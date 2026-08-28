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

import 'dart:io' show Process;

import 'package:file_picker_linux/file_picker_linux.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'file_picker_linux example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = FilePickerLinux();
  final _acceptLabelController = TextEditingController(text: 'Choose');

  bool _lockParentWindow = true;
  bool _useParentWindow = true;
  String _log = 'Nothing picked yet.';

  @override
  void dispose() {
    _acceptLabelController.dispose();
    super.dispose();
  }

  /// Resolves the window identifier the portal needs in order to parent the
  /// dialog.
  ///
  /// Flutter exposes no API for the native window handle, so it has to come
  /// from elsewhere. Under X11, including XWayland, that is the window XID,
  /// which `xdotool` can report. A native Wayland session needs an
  /// `xdg_foreign` exported handle instead, which cannot be obtained this way.
  ///
  /// Shelling out to `xdotool` is not something a shipped app should do. It is
  /// here because it is currently the only way to demonstrate the option.
  Future<String?> _resolveParentWindow() async {
    try {
      final result = await Process.run('xdotool', ['getactivewindow']);
      final xid = (result.stdout as String).trim(); // e.g. 25165834
      return xid.isEmpty ? null : xid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pick() async {
    final parentWindow = _useParentWindow ? await _resolveParentWindow() : null;

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
      body: Padding(
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
              title: const Text('Resolve parentWindow'),
              subtitle: const Text(
                'Without it the portal has no window to be modal against, so '
                'the dialog is not actually locked. Needs xdotool and an X11 '
                'or XWayland session.',
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
