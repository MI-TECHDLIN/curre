import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paths.dart';

/// Films the real app as a phone-screen clip.
///
/// The widget tree advances one 30 fps frame at a time with `tester.pump`;
/// every frame of the phone screen is captured at three times its logical
/// size (1176×2550 for a 392×850 phone) and piped to ffmpeg, so the motion
/// layer's camera can zoom to about 2.5× and still show text drawn above
/// delivery resolution, never an enlarged bitmap. Beside each clip a JSON
/// sidecar records every tap and every named zoom target, in the phone's
/// logical pixels, at the time it happened.
///
/// `--dart-define=FILM_PREVIEW=true` writes a PNG every half second
/// instead of a video, for checking a shot quickly.
class PhoneFilm {
  PhoneFilm(this.tester, this.name, {this.size = phone, this.chrome = true});

  /// The logical size filmed: a phone screen, or a square for a mark.
  final Size size;

  /// Whether to draw the status bar and gesture bar.
  final bool chrome;

  static const fps = 30;
  static const phone = Size(392, 850);
  static const ratio = 3.0;
  static const statusBar = 36.0;
  static const gestureBar = 18.0;
  static const preview = bool.fromEnvironment('FILM_PREVIEW');
  static const ffmpeg = String.fromEnvironment('FILM_FFMPEG');

  final WidgetTester tester;
  final String name;
  final _boundary = GlobalKey();

  /// A drawn surface over the app (another app, the notification shade).
  final overlay = ValueNotifier<Widget?>(null);

  /// The time shown in the drawn status bar.
  final clock = ValueNotifier<String>('17:20');
  final _taps = <Map<String, Object?>>[];
  final _marks = <Map<String, Object?>>[];
  final _beats = <Map<String, Object?>>[];
  /// Called before each frame with the clip time, so the app's clock can
  /// move with the film.
  void Function(double t)? onFrame;
  Process? _encoder;
  int frame = 0;
  Duration _pumped = Duration.zero;

  double get t => frame / fps;

  Future<void> open(Widget app) async {
    tester.view.physicalSize = size * ratio;
    tester.view.devicePixelRatio = ratio;
    tester.view.padding = chrome
        ? const FakeViewPadding(
            top: statusBar * ratio,
            bottom: gestureBar * ratio,
          )
        : FakeViewPadding.zero;
    tester.view.viewPadding = tester.view.padding;
    debugDisableShadows = false;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: chrome ? PhoneScreen(film: this, app: app) : app,
      ),
    );
    final w = (size.width * ratio).toInt(), h = (size.height * ratio).toInt();
    if (!preview) {
      Directory('${FilmPaths.out}/clips').createSync(recursive: true);
      _encoder = await tester.runAsync(
        () => Process.start(ffmpeg, [
          '-y', '-loglevel', 'error', //
          '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${w}x$h',
          '-r', '$fps', '-i', '-',
          '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '12',
          '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
          '${FilmPaths.out}/clips/$name.mp4',
        ]),
      );
      unawaited(_encoder!.stderr.forEach(stderr.add));
    } else {
      Directory('${FilmPaths.out}/preview/$name').createSync(recursive: true);
    }
  }

  /// Lets the app settle before recording starts, without filming it.
  Future<void> settle([double seconds = 1.0]) async {
    for (var i = 0; i < (seconds * fps).round(); i++) {
      await tester.pump(const Duration(microseconds: 33333));
    }
  }

  /// Renders and records one frame.
  Future<void> step() async {
    onFrame?.call(t);
    final target = Duration(microseconds: (frame + 1) * 1000000 ~/ fps);
    await tester.pump(target - _pumped);
    _pumped = target;
    await _capture();
    frame++;
  }

  Future<void> _capture() async {
    final still = preview && frame % (fps ~/ 2) == 0;
    if (preview && !still) return;
    await tester.runAsync(() async {
      final boundary =
          _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: preview ? 1 : ratio);
      if (still) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final label = t.toStringAsFixed(1).padLeft(5, '0');
        File('${FilmPaths.out}/preview/$name/t$label.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      } else {
        final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        _encoder!.stdin.add(raw!.buffer.asUint8List());
        await _encoder!.stdin.flush();
      }
      image.dispose();
    });
  }

  /// Records frames until clip time [seconds].
  Future<void> until(double seconds) async {
    while (t < seconds - 1e-6) {
      await step();
    }
  }

  Future<void> hold(double seconds) => until(t + seconds);

  /// Notes a named moment for the motion layer (a cut, a title cue).
  void beat(String id) => _beats.add({'id': id, 't': _round(t)});

  /// Records the on-screen rectangle of [finder] under [id], for a zoom.
  void mark(String id, Finder finder, {EdgeInsets pad = EdgeInsets.zero}) {
    final rect = pad.inflateRect(tester.getRect(finder.first));
    _marks.add({
      'id': id,
      't': _round(t),
      'x': _round(rect.left),
      'y': _round(rect.top),
      'w': _round(rect.width),
      'h': _round(rect.height),
    });
  }

  /// Taps [finder] the way a finger would: the tap is noted for the drawn
  /// touch, held for [lead] seconds so the touch can arrive, then sent to
  /// the real widget.
  Future<void> tap(Finder finder, {double lead = 0.45, double after = 0.2}) async {
    await reveal(finder);
    await hold(lead);
    final at = tester.getCenter(finder.first);
    if (const bool.fromEnvironment('FILM_DEBUG')) {
      // ignore: avoid_print
      print('tap at $at, t=$t');
    }
    _taps.add({'t': _round(t), 'x': _round(at.dx), 'y': _round(at.dy)});
    await tester.tapAt(at);
    await hold(after);
  }

  /// Scrolls [finder] into view with the app's own scroll physics, filmed.
  Future<void> reveal(
    Finder finder, {
    double alignment = 0.5,
    bool force = false,
  }) async {
    final element = finder.evaluate().first;
    if (Scrollable.maybeOf(element) == null) return;
    final box = element.renderObject! as RenderBox;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    // Home's dock and its All apps line cover the bottom 130 points.
    if (!force && top >= statusBar + 8 && bottom <= phone.height - 130) return;
    unawaited(
      Scrollable.ensureVisible(
        element,
        alignment: alignment,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      ),
    );
    await hold(0.6);
  }

  /// Types into a text field at a human pace.
  Future<void> type(Finder field, String text, {double cps = 17}) async {
    final start = t;
    for (var i = 1; i <= text.length; i++) {
      await tester.enterText(field, text.substring(0, i));
      await until(start + i / cps);
    }
  }

  /// Shows a drawn surface over the app, or clears it with null.
  void show(Widget? surface) => overlay.value = surface;

  Future<void> finish() async {
    final sidecar = {
      'name': name,
      'fps': fps,
      'width': size.width,
      'height': size.height,
      'ratio': ratio,
      'duration': _round(t),
      'taps': _taps,
      'marks': _marks,
      'beats': _beats,
    };
    Directory('${FilmPaths.out}/clips').createSync(recursive: true);
    File('${FilmPaths.out}/clips/$name.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sidecar));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 30));
    final encoder = _encoder;
    if (encoder != null) {
      await tester.runAsync(() async {
        await encoder.stdin.close();
        final code = await encoder.exitCode;
        if (code != 0) throw StateError('ffmpeg exited with $code for $name');
      });
    }
    debugDisableShadows = true;
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}

/// The phone screen: the real app, a drawn status bar and gesture bar, and
/// any drawn surface on top.
class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key, required this.film, required this.app});

  final PhoneFilm film;
  final Widget app;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Stack(
    fit: StackFit.expand,
    children: [
      app,
      ValueListenableBuilder<Widget?>(
        valueListenable: film.overlay,
        builder: (context, surface, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: surface == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : AbsorbPointer(key: surface.key, child: surface),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: PhoneFilm.statusBar,
        child: ValueListenableBuilder<String>(
          valueListenable: film.clock,
          builder: (context, time, _) => StatusBar(time: time),
        ),
      ),
      const Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: PhoneFilm.gestureBar,
        child: IgnorePointer(child: GestureBar()),
      ),
    ],
  ),
  );
}

/// A plain status bar in Curre's ink: the time, signal, Wi-Fi and battery.
/// No handset or OS branding.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.time, this.ink});

  final String time;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final color = ink ?? const Color(0xFF1E1A16);
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 10, 24, 0),
        child: Row(
          children: [
            Text(
              time,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'Geologica',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            CustomPaint(size: const Size(52, 14), painter: _Signals(color)),
          ],
        ),
      ),
    );
  }
}

class _Signals extends CustomPainter {
  _Signals(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    // Signal: four rising bars.
    for (var i = 0; i < 4; i++) {
      final h = 4.0 + i * 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 4.0, size.height - h, 2.6, h),
          const Radius.circular(1),
        ),
        fill,
      );
    }
    // Wi-Fi: a filled quarter fan.
    final fan = Path()
      ..moveTo(24, size.height)
      ..arcTo(
        Rect.fromCircle(center: Offset(24, size.height), radius: 11),
        -2.36,
        1.57,
        false,
      )
      ..close();
    canvas.drawPath(fan, fill);
    // Battery.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 2, 16, 10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 4, 10, 6),
        const Radius.circular(1),
      ),
      fill,
    );
    canvas.drawRect(const Rect.fromLTWH(50.6, 5, 1.6, 4), fill);
  }

  @override
  bool shouldRepaint(_Signals old) => old.color != color;
}

class GestureBar extends StatelessWidget {
  const GestureBar({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 108,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A16).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
