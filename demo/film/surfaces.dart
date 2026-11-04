import 'package:curre/design/design.dart';
import 'package:flutter/material.dart';

/// Film drawings of what Android shows outside Curre: the app a door
/// opens, a chat, the notification shade and the home-app list. They use
/// Curre's tokens and type, with no OS, handset or third-party branding,
/// so the story has context without pretending to be a phone recording.
abstract final class Ink {
  static const paper = Color(0xFFF7F2EA);
  static const raised = Color(0xFFFFFDF9);
  static const sunk = Color(0xFFEEE7DC);
  static const ink = Color(0xFF1E1A16);
  static const ink2 = Color(0xFF5A5048);
  static const ink3 = Color(0xFF6E6257);
  static const hairline = Color(0xFFE2D9CC);
  static const ember = Color(0xFFE85F2E);
  static const shade = Color(0xFF13111A);
  static const shadeCard = Color(0xFF1D1A25);
  static const shadeInk = Color(0xFFF2ECE3);
  static const shadeInk2 = Color(0xFFB9B0A6);
}

TextStyle _t(double size, {FontWeight w = FontWeight.w500, Color c = Ink.ink}) =>
    TextStyle(
      fontFamily: 'Geologica',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: 1.25,
      decoration: TextDecoration.none,
    );

/// A video app opened by Curre's door straight on its search results.
class VideoSearchSurface extends StatelessWidget {
  const VideoSearchSurface({super.key, required this.query});

  final String query;

  static const _results = [
    ('G chord lesson for beginners', '12:04', Color(0xFFCFE2F4)),
    ('G to C: smooth chord changes', '8:31', Color(0xFFF7D3CC)),
    ('Strumming practice in G', '15:47', Color(0xFFDDE9CF)),
  ];

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Ink.raised,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 46, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Ink.sunk,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const _Lens(),
                const SizedBox(width: 10),
                Text(query, style: _t(16, w: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final (title, length, tint) in _results) ...[
            _VideoCard(title: title, length: length, tint: tint),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );
}

class _Lens extends StatelessWidget {
  const _Lens();

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Ink.ink2, width: 2.2),
    ),
  );
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.title,
    required this.length,
    required this.tint,
  });

  final String title;
  final String length;
  final Color tint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AspectRatio(
        aspectRatio: 16 / 8.2,
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Six strings and a few frets: a guitar neck, drawn.
              Positioned.fill(child: CustomPaint(painter: _Neck())),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Ink.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Ink.raised,
                    size: 32,
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Ink.ink.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(length, style: _t(12, c: Ink.raised)),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(title, style: _t(15, w: FontWeight.w600)),
    ],
  );
}

class _Neck extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final string = Paint()
      ..color = Ink.ink.withValues(alpha: 0.18)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.24 + i * 0.105);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), string);
    }
    final fret = Paint()
      ..color = Ink.ink.withValues(alpha: 0.12)
      ..strokeWidth = 3;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.8),
        fret,
      );
    }
  }

  @override
  bool shouldRepaint(_Neck oldDelegate) => false;
}

/// A chat opened by a conversation shortcut.
class ChatSurface extends StatelessWidget {
  const ChatSurface({super.key, required this.person, required this.messages});

  final String person;
  final List<(String, bool)> messages;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Ink.raised,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 46, 16, 28),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7D3CC),
                  shape: BoxShape.circle,
                ),
                child: Text(person[0], style: _t(18, w: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Text(person, style: _t(18, w: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Ink.hairline, height: 1),
          const Spacer(),
          for (final (text, mine) in messages)
            Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 260),
                decoration: BoxDecoration(
                  color: mine ? const Color(0xFFCFE2F4) : Ink.sunk,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(text, style: _t(15)),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Ink.sunk,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Text('Message', style: _t(15, c: Ink.ink3)),
          ),
        ],
      ),
    ),
  );
}

/// One notification in the drawn shade.
class ShadeNote {
  const ShadeNote({
    required this.app,
    required this.title,
    required this.text,
    required this.time,
    this.held = false,
  });

  final String app;
  final String title;
  final String text;
  final String time;

  /// Caught by Curre's quieting: shown leaving the shade, held by Curre.
  final bool held;
}

/// The notification shade pulled over Home, with its notifications.
/// [heldProgress] runs 0..1 as a held notification folds away into
/// "Held by Curre".
class NotificationShade extends StatelessWidget {
  const NotificationShade({
    super.key,
    required this.notes,
    this.heldProgress = 0,
    this.date = 'Tuesday, 3 November',
  });

  final List<ShadeNote> notes;
  final double heldProgress;
  final String date;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Ink.shade.withValues(alpha: 0.96),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 52, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 14),
            child: Text(date, style: _t(15, c: Ink.shadeInk2)),
          ),
          for (final note in notes) _NoteCard(note: note, held: heldProgress),
        ],
      ),
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.held});

  final ShadeNote note;
  final double held;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Ink.shadeCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFCFE2F4).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(note.app[0], style: _t(16, w: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${note.app} · ${note.time}',
                  style: _t(12.5, c: Ink.shadeInk2),
                ),
                const SizedBox(height: 2),
                Text(note.title, style: _t(15.5, w: FontWeight.w600, c: Ink.shadeInk)),
                Text(note.text, style: _t(14.5, c: Ink.shadeInk2)),
              ],
            ),
          ),
        ],
      ),
    );
    if (!note.held) return card;
    final p = Curves.easeInOutCubic.transform(held.clamp(0.0, 1.0));
    return Stack(
      children: [
        Opacity(
          opacity: 1 - p,
          child: Transform.scale(
            scale: 1 - 0.15 * p,
            alignment: Alignment.topCenter,
            child: card,
          ),
        ),
        if (p > 0)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: p,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCC35A),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CurreGlyph(CurreGlyphKind.notify, size: 18, color: Ink.ink),
                      const SizedBox(width: 8),
                      Text(
                        'Held by Curre · ${note.app} is hidden',
                        style: _t(14, w: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Android's list of home apps, drawn plainly.
class HomeAppList extends StatelessWidget {
  const HomeAppList({super.key, this.chosen = 'Curre'});

  final String chosen;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Ink.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default home app', style: _t(26, w: FontWeight.w700)),
          const SizedBox(height: 24),
          for (final (name, hint) in const [
            ('Curre', 'Your focus home screen'),
            ('Launcher', 'Your phone’s usual home screen'),
          ])
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Ink.raised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Ink.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Ink.ink, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: chosen == name
                        ? Container(
                            width: 11,
                            height: 11,
                            decoration: const BoxDecoration(
                              color: Ink.ink,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: _t(17, w: FontWeight.w600)),
                      Text(hint, style: _t(14, c: Ink.ink3)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
