import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_channel.dart';
import 'voice_model.dart';

/// The kind of connection the phone has right now.
enum VoiceNetwork {
  none,

  /// Wi-Fi or another connection Android counts as unmetered.
  unmetered,

  /// Mobile data or a hotspot Android counts as metered.
  metered,

  /// The phone could not say. Treated like mobile data: never assumed free.
  unknown,
}

/// What the phone says about downloading right now.
@immutable
class VoiceDownloadConditions {
  const VoiceDownloadConditions({
    required this.network,
    this.batteryLow = false,
  });

  static const unknown = VoiceDownloadConditions(network: VoiceNetwork.unknown);

  final VoiceNetwork network;

  /// Low and not charging, or Battery Saver is on.
  final bool batteryLow;
}

/// Reads the phone's connection and battery for the voice download.
abstract interface class VoiceConditionsGateway {
  Future<VoiceDownloadConditions> read();
}

/// Asks Android through Curre's channel (`MainActivity.kt`,
/// `voiceDownloadConditions`).
class ChannelVoiceConditions implements VoiceConditionsGateway {
  const ChannelVoiceConditions();

  @override
  Future<VoiceDownloadConditions> read() async {
    final Map<Object?, Object?>? answer;
    try {
      answer = await currePlatformChannel.invokeMapMethod<Object?, Object?>(
        'voiceDownloadConditions',
      );
    } on Object {
      return VoiceDownloadConditions.unknown;
    }
    if (answer == null) return VoiceDownloadConditions.unknown;
    final online = answer['online'] == true;
    return VoiceDownloadConditions(
      network: !online
          ? VoiceNetwork.none
          : answer['unmetered'] == true
          ? VoiceNetwork.unmetered
          : VoiceNetwork.metered,
      batteryLow: answer['batteryLow'] == true,
    );
  }
}

/// The two choices the voice download remembers.
@immutable
class VoicePrefetchChoices {
  const VoicePrefetchChoices({this.auto = true, this.onMobileData = false});

  /// Download by itself when conditions allow. Removing the voice files
  /// turns this off; the mic or Settings turn it back on.
  final bool auto;

  /// "Download voice on mobile data". Off unless the person turns it on.
  final bool onMobileData;

  VoicePrefetchChoices copyWith({bool? auto, bool? onMobileData}) =>
      VoicePrefetchChoices(
        auto: auto ?? this.auto,
        onMobileData: onMobileData ?? this.onMobileData,
      );
}

abstract interface class VoicePrefetchChoiceStore {
  Future<VoicePrefetchChoices> load();
  Future<void> save(VoicePrefetchChoices choices);
}

class MemoryVoicePrefetchChoices implements VoicePrefetchChoiceStore {
  MemoryVoicePrefetchChoices([this.choices = const VoicePrefetchChoices()]);

  VoicePrefetchChoices choices;

  @override
  Future<VoicePrefetchChoices> load() async => choices;

  @override
  Future<void> save(VoicePrefetchChoices choices) async =>
      this.choices = choices;
}

class SharedPreferencesVoicePrefetchChoices
    implements VoicePrefetchChoiceStore {
  const SharedPreferencesVoicePrefetchChoices();

  static const _auto = 'curre.voice.autoDownload';
  static const _onMobileData = 'curre.voice.downloadOnMobileData';

  @override
  Future<VoicePrefetchChoices> load() async {
    final preferences = await SharedPreferences.getInstance();
    return VoicePrefetchChoices(
      auto: preferences.getBool(_auto) ?? true,
      onMobileData: preferences.getBool(_onMobileData) ?? false,
    );
  }

  @override
  Future<void> save(VoicePrefetchChoices choices) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_auto, choices.auto);
    await preferences.setBool(_onMobileData, choices.onMobileData);
  }
}

enum VoicePrefetchPhase {
  /// Not looked yet.
  checking,

  /// Every file is on the phone and checked: voice works offline.
  ready,

  downloading,

  /// On mobile data, which the person has not allowed for the download.
  waitingForWifi,

  /// No connection, or it dropped. What arrived is kept.
  waitingForConnection,

  /// Low battery or Battery Saver: the download waits for a charge.
  waitingForBattery,

  /// The download hit a problem ([VoicePrefetcher.problem]); it tries again
  /// on the next start, or when asked.
  stopped,

  /// The voice files were removed: nothing downloads until the mic or
  /// Settings ask for it.
  off,

  /// This build has no voice typing (a web review build).
  unavailable,
}

enum _StopReason { conditions, removed, disposed }

/// Fetches the voice model quietly in the background, so it is usually
/// ready by the first mic tap.
///
/// By itself it downloads only on Wi-Fi with enough battery, pausing (and
/// keeping what arrived) when either changes. An explicit "Download now"
/// ignores both until the files are ready. It runs while Curre's process
/// does, home screen included, and picks up again on the next start.
class VoicePrefetcher extends ChangeNotifier {
  VoicePrefetcher({
    required this.models,
    VoiceConditionsGateway? conditions,
    VoicePrefetchChoiceStore? choices,
    this.recheckEvery,
    this.conditionsCheckEvery = const Duration(seconds: 15),
    DateTime Function()? now,
  }) : _conditions = conditions ?? const ChannelVoiceConditions(),
       _choiceStore = choices ?? MemoryVoicePrefetchChoices(),
       _now = now ?? DateTime.now;

  final VoiceModelStore models;
  final VoiceConditionsGateway _conditions;
  final VoicePrefetchChoiceStore _choiceStore;
  final DateTime Function() _now;

  /// How often a waiting download looks again at the connection and
  /// battery. Null looks only on start, resume and when asked.
  final Duration? recheckEvery;

  /// How often a running download makes sure it is still allowed to run.
  final Duration conditionsCheckEvery;

  var _phase = VoicePrefetchPhase.checking;
  var _choices = const VoicePrefetchChoices();
  var _choicesLoaded = false;
  Future<void>? _loading;
  var _started = false;
  var _explicit = false;
  var _received = 0;
  VoiceDownloadProblem? _problem;
  VoiceModelPaths? _model;
  VoiceDownloadCancel? _cancel;
  _StopReason? _stopReason;
  VoicePrefetchPhase? _pauseAs;
  Timer? _recheck;
  var _evaluating = false;
  var _evaluateAgain = false;

  /// A download is running, or a cancelled one is still letting go of its
  /// files. Only one runs at a time.
  var _running = false;
  var _evaluateAfterRun = false;
  var _stopped = false;

  VoicePrefetchPhase get phase => _phase;

  /// Bytes on the phone so far, a stopped download's part included.
  int get received => _received;
  int get total => models.spec.bytes;

  /// What is left to fetch.
  int get remaining => (total - _received).clamp(0, total);

  /// How far along, 0 to 1.
  double get fraction => total == 0 ? 0 : (_received / total).clamp(0.0, 1.0);

  /// Why the last download stopped, while [phase] is
  /// [VoicePrefetchPhase.stopped].
  VoiceDownloadProblem? get problem => _problem;

  /// The checked files, once [phase] is [VoicePrefetchPhase.ready].
  VoiceModelPaths? get model => _model;

  bool get onMobileData => _choices.onMobileData;
  bool get autoDownload => _choices.auto;

  /// Starts the quiet download if the voice files are missing. Safe to call
  /// again: it then looks afresh.
  Future<void> start() async {
    _started = true;
    _stopped = false;
    await _evaluate();
  }

  /// Looks again, as when Curre comes back to the front. Does nothing
  /// before [start].
  Future<void> recheck() async {
    if (!_started) return;
    await _evaluate();
  }

  /// The installed files, or null. Also brings [phase] up to date when the
  /// files turned up some other way.
  Future<VoiceModelPaths?> installed() async {
    final paths = await models.installed();
    if (paths != null && _phase != VoicePrefetchPhase.ready) {
      _model = paths;
      _received = total;
      _set(VoicePrefetchPhase.ready);
    }
    return paths;
  }

  /// The mic was tapped before the files were ready: turn the quiet
  /// download back on, if removing the files had turned it off.
  Future<void> wantVoice() async {
    await _loadChoices();
    if (!_choices.auto) await _saveChoices(_choices.copyWith(auto: true));
    await start();
  }

  /// "Download now": fetch right away, on mobile data or a low battery too,
  /// because the person asked having seen the size.
  Future<void> downloadNow() async {
    await _loadChoices();
    _explicit = true;
    if (!_choices.auto) await _saveChoices(_choices.copyWith(auto: true));
    await start();
  }

  Future<void> setOnMobileData(bool value) async {
    await _loadChoices();
    if (_choices.onMobileData == value) return;
    await _saveChoices(_choices.copyWith(onMobileData: value));
    notifyListeners();
    if (_started || value) await start();
  }

  /// Stops any download, removes the voice files and keeps the quiet
  /// download off until the mic or Settings ask again. Throws when the
  /// files could not be removed.
  Future<void> remove() async {
    await _loadChoices();
    _explicit = false;
    _cancelDownload(_StopReason.removed);
    _recheck?.cancel();
    await _saveChoices(_choices.copyWith(auto: false));
    try {
      await models.remove();
    } finally {
      await _refreshBytes();
      _model = null;
      _problem = null;
      _set(VoicePrefetchPhase.off);
    }
  }

  /// The installed files would not load: fetch them fresh, now.
  Future<void> replace() async {
    _cancelDownload(_StopReason.removed);
    try {
      await models.remove();
    } on Object {
      // A fresh download overwrites what is left.
    }
    _model = null;
    _received = 0;
    _set(VoicePrefetchPhase.checking);
    await downloadNow();
  }

  /// Stops downloading and looking, for good (the app is closing).
  void stop() {
    _stopped = true;
    _started = false;
    _recheck?.cancel();
    _recheck = null;
    _cancelDownload(_StopReason.disposed);
  }

  Future<void> _loadChoices() {
    if (_choicesLoaded) return Future.value();
    return _loading ??= () async {
      try {
        _choices = await _choiceStore.load();
      } on Object {
        // Defaults: Wi-Fi only, on.
      }
      _choicesLoaded = true;
    }();
  }

  Future<void> _saveChoices(VoicePrefetchChoices choices) async {
    _choices = choices;
    try {
      await _choiceStore.save(choices);
    } on Object {
      // Kept for this run even if the phone could not store it.
    }
  }

  Future<void> _refreshBytes() async {
    try {
      _received = await models.bytesOnPhone();
    } on Object {
      _received = 0;
    }
  }

  Future<void> _evaluate() async {
    if (_evaluating) {
      _evaluateAgain = true;
      return;
    }
    _evaluating = true;
    try {
      do {
        _evaluateAgain = false;
        await _evaluateOnce();
      } while (_evaluateAgain && !_stopped);
    } finally {
      _evaluating = false;
    }
  }

  Future<void> _evaluateOnce() async {
    if (_stopped) return;
    if (_running) {
      _evaluateAfterRun = true;
      return;
    }
    _recheck?.cancel();
    await _loadChoices();
    final VoiceModelPaths? paths;
    try {
      paths = await models.installed();
      await _refreshBytes();
    } on Object {
      _set(VoicePrefetchPhase.unavailable);
      return;
    }
    if (paths != null) {
      _model = paths;
      _received = total;
      _explicit = false;
      _set(VoicePrefetchPhase.ready);
      return;
    }
    if (!_choices.auto && !_explicit) {
      _set(VoicePrefetchPhase.off);
      return;
    }
    final waiting = _waitingFor(await _readConditions());
    if (waiting != null) {
      _set(waiting);
      _scheduleRecheck();
      return;
    }
    // Not awaited: callers never wait on a 104 MB download.
    unawaited(_download());
  }

  Future<VoiceDownloadConditions> _readConditions() async {
    try {
      return await _conditions.read();
    } on Object {
      return VoiceDownloadConditions.unknown;
    }
  }

  /// Why the download must wait under [conditions], or null to go ahead.
  VoicePrefetchPhase? _waitingFor(VoiceDownloadConditions conditions) {
    if (conditions.network == VoiceNetwork.none) {
      return VoicePrefetchPhase.waitingForConnection;
    }
    if (_explicit) return null;
    if (conditions.batteryLow) return VoicePrefetchPhase.waitingForBattery;
    if (conditions.network != VoiceNetwork.unmetered &&
        !_choices.onMobileData) {
      return VoicePrefetchPhase.waitingForWifi;
    }
    return null;
  }

  void _scheduleRecheck() {
    final every = recheckEvery;
    if (every == null || _stopped) return;
    _recheck?.cancel();
    _recheck = Timer(every, () => unawaited(_evaluate()));
  }

  Future<void> _download() async {
    _running = true;
    try {
      await _downloadOnce();
    } finally {
      _running = false;
      if (_evaluateAfterRun && !_stopped) {
        _evaluateAfterRun = false;
        unawaited(_evaluate());
      }
    }
  }

  Future<void> _downloadOnce() async {
    final cancel = _cancel = VoiceDownloadCancel();
    _stopReason = null;
    _pauseAs = null;
    _problem = null;
    _set(VoicePrefetchPhase.downloading);
    var lastLook = _now();
    var looking = false;
    var shownMegabytes = _received ~/ 1000000;
    try {
      final paths = await models.download(
        cancel: cancel,
        onProgress: (received, _) {
          _received = received;
          final megabytes = received ~/ 1000000;
          if (megabytes != shownMegabytes) {
            shownMegabytes = megabytes;
            notifyListeners();
          }
          final now = _now();
          if (looking || now.difference(lastLook) < conditionsCheckEvery) {
            return;
          }
          lastLook = now;
          looking = true;
          unawaited(
            _readConditions().then((conditions) {
              looking = false;
              final waiting = _waitingFor(conditions);
              if (waiting == null || cancel.isCancelled) return;
              _pauseAs = waiting;
              _cancelDownload(_StopReason.conditions);
            }),
          );
        },
      );
      _cancel = null;
      _model = paths;
      _received = total;
      _explicit = false;
      _set(VoicePrefetchPhase.ready);
    } on VoiceDownloadCancelled {
      _cancel = null;
      await _refreshBytes();
      switch (_stopReason) {
        case _StopReason.conditions:
          _set(_pauseAs ?? VoicePrefetchPhase.waitingForWifi);
          _scheduleRecheck();
        case _StopReason.removed || _StopReason.disposed || null:
          break;
      }
    } on VoiceDownloadException catch (error) {
      _cancel = null;
      await _refreshBytes();
      if (error.problem == VoiceDownloadProblem.offline) {
        _set(VoicePrefetchPhase.waitingForConnection);
        _scheduleRecheck();
      } else {
        _problem = error.problem;
        _set(VoicePrefetchPhase.stopped);
      }
    } on Object {
      _cancel = null;
      _problem = VoiceDownloadProblem.server;
      _set(VoicePrefetchPhase.stopped);
    }
  }

  void _cancelDownload(_StopReason reason) {
    final cancel = _cancel;
    if (cancel == null) return;
    _stopReason = reason;
    _cancel = null;
    cancel.cancel();
  }

  void _set(VoicePrefetchPhase phase) {
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
