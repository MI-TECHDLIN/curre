import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'door_models.dart';
import 'door_router.dart';
import 'launcher_channel.dart';
import 'query_door_allowlist.dart';

class DoorLabScreen extends StatefulWidget {
  const DoorLabScreen({super.key});

  @override
  State<DoorLabScreen> createState() => _DoorLabScreenState();
}

class _DoorLabScreenState extends State<DoorLabScreen>
    with WidgetsBindingObserver {
  static const DoorPlatform _platform = LauncherChannel();
  static const List<_LabApp> _labApps = <_LabApp>[
    _LabApp('YouTube', 'com.google.android.youtube', queryDoorId: 'youtube'),
    _LabApp('Instagram', 'com.instagram.android'),
    _LabApp('WhatsApp', 'com.whatsapp'),
    _LabApp('Spotify', 'com.spotify.music'),
    _LabApp('Google Maps', 'com.google.android.apps.maps', queryDoorId: 'maps'),
  ];

  final TextEditingController _targetController = TextEditingController(
    text: 'G chord',
  );
  final Map<String, bool> _installed = <String, bool>{};
  final Map<String, List<AppShortcut>> _staticShortcuts =
      <String, List<AppShortcut>>{};
  final Map<String, List<AppShortcut>> _conversationShortcuts =
      <String, List<AppShortcut>>{};
  final Set<String> _conversationLoaded = <String>{};
  final List<_Attempt> _attempts = <_Attempt>[];

  late final DoorRouter _router;
  bool _loading = true;
  bool _hostPermission = false;
  String _status = 'Reading launcher capabilities…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = DoorRouter(
      _platform,
      copyTarget: (value) => Clipboard.setData(ClipboardData(text: value)),
    );
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _targetController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _status = 'Reading apps and shortcuts…';
      });
    }
    try {
      final apps = await _platform.listApps();
      final packages = apps.map((app) => app.packageName).toSet();
      final host = await _platform.hasShortcutHostPermission();
      final staticResults = <String, List<AppShortcut>>{};
      for (final app in _labApps) {
        if (!packages.contains(app.packageName) || !host) {
          staticResults[app.packageName] = const <AppShortcut>[];
          continue;
        }
        staticResults[app.packageName] = await _safeShortcuts(
          () => _platform.getStaticShortcuts(app.packageName),
        );
      }
      if (!mounted) return;
      setState(() {
        _hostPermission = host;
        for (final app in _labApps) {
          _installed[app.packageName] = packages.contains(app.packageName);
        }
        _staticShortcuts
          ..clear()
          ..addAll(staticResults);
        for (final app in _labApps) {
          if (!packages.contains(app.packageName) || !host) {
            _conversationShortcuts.remove(app.packageName);
            _conversationLoaded.remove(app.packageName);
          }
        }
        _loading = false;
        _status = host
            ? 'Shortcut host permission granted.'
            : 'Set Curre as Home to read and start shortcuts.';
      });
    } on PlatformException catch (error) {
      _setError(error.message ?? error.code);
    } on Object catch (error) {
      _setError(error.toString());
    }
  }

  Future<List<AppShortcut>> _safeShortcuts(
    Future<List<AppShortcut>> Function() read,
  ) async {
    try {
      return await read();
    } on Object {
      return const <AppShortcut>[];
    }
  }

  Future<void> _loadConversations(_LabApp app) async {
    if (!_hostPermission || !(_installed[app.packageName] ?? false)) {
      _showMessage('Set Curre as Home and install ${app.label} first.');
      return;
    }
    final shortcuts = await _safeShortcuts(
      () => _platform.getConversationShortcuts(app.packageName),
    );
    if (!mounted) return;
    setState(() {
      _conversationShortcuts[app.packageName] = shortcuts;
      _conversationLoaded.add(app.packageName);
    });
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = 'Could not refresh: $message';
    });
  }

  Future<void> _requestHome() async {
    try {
      await _platform.requestHomeRole();
      _showMessage('Choose Curre as the default Home, then return here.');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? error.code);
    }
  }

  String? get _target {
    final value = _targetController.text.trim();
    if (value.isEmpty) {
      _showMessage('Type a target word first.');
      return null;
    }
    return value;
  }

  Future<void> _fire(
    String app,
    String door,
    String target,
    Future<String> Function() action, {
    bool sensitive = false,
  }) async {
    final attempt = _Attempt(
      app: app,
      door: door,
      target: target,
      sensitive: sensitive,
    );
    setState(() => _attempts.insert(0, attempt));
    try {
      final detail = await action();
      if (!mounted) return;
      setState(() => attempt.invocation = detail);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(
        () => attempt.invocation = 'ERROR: ${error.message ?? error.code}',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => attempt.invocation = 'ERROR: $error');
    }
  }

  Future<void> _fireShortcut(_LabApp app, AppShortcut shortcut) async {
    final target = _targetController.text.trim();
    await _fire(
      app.label,
      'static shortcut: ${shortcut.shortLabel}',
      target,
      () async {
        final ok = await _platform.startShortcut(app.packageName, shortcut.id);
        return ok ? 'launch requested' : 'launch rejected';
      },
    );
  }

  Future<void> _fireConversation(_LabApp app, AppShortcut shortcut) async {
    final person = _target;
    if (person == null) return;
    await _fire(
      app.label,
      'conversation: ${shortcut.shortLabel}',
      person,
      () async {
        final result = await _router.open(
          DoorRequest(
            packageName: app.packageName,
            kind: ReasonKind.person,
            person: shortcut.shortLabel,
            target: person,
            conversationShortcuts:
                _conversationShortcuts[app.packageName] ??
                const <AppShortcut>[],
            staticShortcuts:
                _staticShortcuts[app.packageName] ?? const <AppShortcut>[],
          ),
        );
        return result.kind.name;
      },
      sensitive: true,
    );
  }

  Future<void> _fireQuery(_LabApp app) async {
    final target = _target;
    if (target == null || app.queryDoorId == null) return;
    await _fire(app.label, 'query link: ${app.queryDoorId}', target, () async {
      final result = await _router.open(
        DoorRequest(
          packageName: app.packageName,
          kind: ReasonKind.task,
          target: target,
          queryDoorId: app.queryDoorId,
          staticShortcuts:
              _staticShortcuts[app.packageName] ?? const <AppShortcut>[],
        ),
      );
      return '${result.kind.name}: ${result.detail ?? ''}'.trim();
    });
  }

  Future<void> _fireWebSearch() async {
    final target = _target;
    if (target == null) return;
    await _fire('System', 'query link: web', target, () async {
      final ok = await _platform.launchQueryDoor('web', target);
      return ok ? 'launch requested' : 'launch rejected';
    });
  }

  Future<void> _fireFallback(_LabApp app) async {
    final target = _target;
    if (target == null) return;
    await _fire(app.label, 'FR18 fallback', target, () async {
      final result = await _router.fallback(
        DoorRequest(
          packageName: app.packageName,
          kind: ReasonKind.task,
          target: target,
          staticShortcuts:
              _staticShortcuts[app.packageName] ?? const <AppShortcut>[],
        ),
      );
      return '${result.kind.name}; copied target to clipboard';
    });
  }

  Future<void> _export() async {
    final buffer = StringBuffer()
      ..writeln('Curre Door Lab results')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('Shortcut host permission: $_hostPermission')
      ..writeln();
    for (final app in _labApps) {
      final statics =
          _staticShortcuts[app.packageName] ?? const <AppShortcut>[];
      final conversations =
          _conversationShortcuts[app.packageName] ?? const <AppShortcut>[];
      buffer
        ..writeln('${app.label} (${app.packageName})')
        ..writeln('  installed: ${_installed[app.packageName] ?? false}')
        ..writeln(
          '  static: ${statics.isEmpty ? 'none' : statics.map((s) => s.shortLabel).join(' | ')}',
        )
        ..writeln(
          '  conversations: ${!_conversationLoaded.contains(app.packageName)
              ? 'not read'
              : conversations.isEmpty
              ? 'none'
              : '${conversations.length} found (labels kept on device)'}',
        );
    }
    buffer
      ..writeln()
      ..writeln('Door checks:');
    if (_attempts.isEmpty) {
      buffer.writeln('- none run');
    }
    for (final attempt in _attempts.reversed) {
      final verdict = switch (attempt.passed) {
        true => 'PASS',
        false => 'FAIL',
        null => 'UNMARKED',
      };
      final door = attempt.sensitive ? 'conversation shortcut' : attempt.door;
      final target = attempt.sensitive ? '[kept on device]' : attempt.target;
      final note = attempt.sensitive
          ? '[kept on device]'
          : attempt.note.isEmpty
          ? '-'
          : attempt.note;
      buffer.writeln(
        '- $verdict | ${attempt.app} | $door | target="$target" | native=${attempt.invocation} | note=$note',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showMessage('Plain-text results copied to the clipboard.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Curre Door Lab')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Set Curre as the default Home first. Type a target, launch each door, then return here and mark what actually happened.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: _requestHome,
                  child: const Text('Set Curre as Home'),
                ),
                OutlinedButton(
                  onPressed: _loading ? null : _refresh,
                  child: const Text('Refresh doors'),
                ),
                OutlinedButton(
                  onPressed: _export,
                  child: const Text('Export results'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 16),
            TextField(
              controller: _targetController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Target word, query, or person',
                helperText: 'Examples: G chord, Ada, Shoprite Lekki',
              ),
            ),
            const SizedBox(height: 16),
            if (_attempts.isNotEmpty) ...<Widget>[
              Text(
                'Results to mark',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._attempts.map(_attemptCard),
              const Divider(height: 32),
            ],
            Text('Web search', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _fireWebSearch,
              child: const Text('Open web search query door'),
            ),
            const Divider(height: 32),
            ..._labApps.map(_appCard),
          ],
        ),
      ),
    );
  }

  Widget _attemptCard(_Attempt attempt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${attempt.app} — ${attempt.door}'),
            Text('Target: ${attempt.target} · ${attempt.invocation}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => setState(() => attempt.passed = true),
                  child: Text(attempt.passed == true ? 'PASS ✓' : 'Pass'),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() => attempt.passed = false),
                  child: Text(attempt.passed == false ? 'FAIL ✓' : 'Fail'),
                ),
              ],
            ),
            TextFormField(
              initialValue: attempt.note,
              onChanged: (value) => attempt.note = value,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appCard(_LabApp app) {
    final installed = _installed[app.packageName] ?? false;
    final statics = _staticShortcuts[app.packageName] ?? const <AppShortcut>[];
    final conversations =
        _conversationShortcuts[app.packageName] ?? const <AppShortcut>[];
    final conversationsLoaded = _conversationLoaded.contains(app.packageName);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(app.label, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${app.packageName} · ${installed ? 'installed' : 'not installed'}',
            ),
            const SizedBox(height: 12),
            const Text('Static shortcuts'),
            if (statics.isEmpty) const Text('None found'),
            ...statics.map(
              (shortcut) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  onPressed: () => _fireShortcut(app, shortcut),
                  child: Text('Open ${shortcut.shortLabel}'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Conversation candidates (dynamic/pinned/cached; kept on this phone)',
            ),
            OutlinedButton(
              onPressed: installed && _hostPermission
                  ? () => _loadConversations(app)
                  : null,
              child: Text(
                conversationsLoaded
                    ? 'Refresh conversation shortcuts'
                    : 'Read conversation shortcuts',
              ),
            ),
            if (!conversationsLoaded) const Text('Not read yet'),
            if (conversationsLoaded && conversations.isEmpty)
              const Text('None found'),
            ...conversations.map(
              (shortcut) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  onPressed: () => _fireConversation(app, shortcut),
                  child: Text('Open ${shortcut.shortLabel}'),
                ),
              ),
            ),
            if (app.queryDoorId case final doorId?) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Allowlisted query: ${QueryDoorAllowlist.byId(doorId)!.label}',
              ),
              OutlinedButton(
                onPressed: () => _fireQuery(app),
                child: const Text('Open query door'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: installed ? () => _fireFallback(app) : null,
              child: const Text('Run FR18 fallback: Search/app + copy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabApp {
  const _LabApp(this.label, this.packageName, {this.queryDoorId});

  final String label;
  final String packageName;
  final String? queryDoorId;
}

class _Attempt {
  _Attempt({
    required this.app,
    required this.door,
    required this.target,
    required this.sensitive,
  });

  final String app;
  final String door;
  final String target;
  final bool sensitive;
  String invocation = 'launching…';
  bool? passed;
  String note = '';
}
