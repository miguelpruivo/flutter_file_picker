// A runnable example of file_picker_linux.
//
// Its purpose is to show the one thing that is not obvious from the API:
// `lockParentWindow` reaches the XDG portal as `modal`, but the portal also
// needs `parentWindow` to know which window to be modal against. Without it the
// dialog is left unparented and nothing appears to be locked.
//
// Watch what actually goes over the wire while using this app with:
//
//   dbus-monitor --session "interface='org.freedesktop.portal.FileChooser'"

import 'dart:io' show Process, pid;

import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:flutter/material.dart';

/// Resolves the window identifier the portal needs in order to parent the
/// dialog, by looking for an X window that belongs to *this* process.
///
/// Flutter exposes no API for the native window handle, so it has to come from
/// elsewhere. Under X11, including XWayland, that is the window XID.
///
/// `xdotool getactivewindow` is the obvious call here and it is wrong: with
/// XWayland running it happily returns the focused *X* window, which on a
/// Wayland session belongs to some other application entirely. Searching by pid
/// returns nothing when this process has no X window, which is exactly what
/// should happen on a native Wayland session.
///
/// Shelling out to `xdotool` is not something a shipped app should do. It is
/// here because it is currently the only way to demonstrate the option.
Future<String?> resolveParentWindowWithXdotool() async {
  try {
    final result = await Process.run('xdotool', [
      'search',
      '--pid',
      '$pid',
      '--onlyvisible',
    ]);
    final ids = (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return ids.isEmpty ? null : ids.last; // e.g. 25165834
  } catch (_) {
    return null;
  }
}

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    super.key,
    this.resolveParentWindow = resolveParentWindowWithXdotool,
  });

  /// Injected so widget tests do not have to spawn a real process.
  final Future<String?> Function() resolveParentWindow;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'file_picker_linux example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: HomePage(resolveParentWindow: resolveParentWindow),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.resolveParentWindow});

  final Future<String?> Function() resolveParentWindow;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = FilePickerLinux();
  final _acceptLabelController = TextEditingController(text: 'Choose');

  bool _lockParentWindow = true;
  bool _useParentWindow = true;
  String? _parentWindow;
  bool _probed = false;
  String _log = 'Nothing picked yet.';

  @override
  void initState() {
    super.initState();
    _probeParentWindow();
  }

  @override
  void dispose() {
    _acceptLabelController.dispose();
    super.dispose();
  }

  Future<void> _probeParentWindow() async {
    final xid = await widget.resolveParentWindow();
    if (!mounted) return;
    setState(() {
      _parentWindow = xid;
      _probed = true;
    });
  }

  Future<void> _pick() async {
    await _probeParentWindow();
    final parentWindow = _useParentWindow ? _parentWindow : null;

    final acceptLabel = _acceptLabelController.text.trim();
    final file = await _picker.pickFile(
      dialogTitle: 'file_picker_linux example',
      linuxOptions: FilePickerLinuxOptions(
        acceptLabel: acceptLabel.isEmpty ? null : acceptLabel,
        lockParentWindow: _lockParentWindow,
        parentWindow: parentWindow,
      ),
    );

    if (!mounted) return;
    setState(() {
      _log = [
        'modal (lockParentWindow): $_lockParentWindow',
        'parentWindow: ${parentWindow ?? 'none, dialog is unparented'}',
        'picked: ${file?.path ?? 'cancelled'}',
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('file_picker_linux')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('lockParentWindow'),
              subtitle: const Text('Sent to the portal as modal'),
              value: _lockParentWindow,
              onChanged: (v) => setState(() => _lockParentWindow = v),
            ),
            SwitchListTile(
              title: const Text('Send parentWindow'),
              subtitle: const Text(
                'Without it the portal has no window to be modal against, so '
                'the dialog is not actually locked.',
              ),
              value: _useParentWindow,
              onChanged: (v) => setState(() => _useParentWindow = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _acceptLabelController,
              decoration: const InputDecoration(
                labelText: 'acceptLabel',
                helperText: 'Text on the confirmation button',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _ParentWindowStatus(probed: _probed, parentWindow: _parentWindow),
            const SizedBox(height: 24),
            FilledButton(onPressed: _pick, child: const Text('Pick a file')),
            const SizedBox(height: 24),
            Text(_log, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

/// Says up front whether a parent window could be resolved, so the reason a
/// dialog is not modal is visible before picking rather than after.
class _ParentWindowStatus extends StatelessWidget {
  const _ParentWindowStatus({required this.probed, required this.parentWindow});

  final bool probed;
  final String? parentWindow;

  @override
  Widget build(BuildContext context) {
    if (!probed) return const SizedBox.shrink();

    final found = parentWindow != null;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: found ? scheme.secondaryContainer : scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(found ? Icons.check_circle_outline : Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                found
                    ? 'Found an X window for this process: $parentWindow. The '
                          'dialog can be parented, so lockParentWindow will '
                          'actually lock it.'
                    : 'This process has no X window, so the dialog cannot be '
                          'parented and lockParentWindow will have no visible '
                          'effect. That is expected on a native Wayland '
                          'session. Relaunch with GDK_BACKEND=x11 to try the '
                          'X11 path.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
