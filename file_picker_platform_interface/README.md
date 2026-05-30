# file_picker_platform_interface (placeholder)

This directory is a placeholder with notes and a minimal plan to extract the shared
`file_picker` platform interface into its own package in the future.

Why keep this: creating a dedicated `file_picker_platform_interface` package is useful
when you want a fully federated plugin (independent lifecycle for implementations).
However, extracting it now would require moving source files and updating many imports.

Planned steps to extract (copy/paste when ready):

1. Create package skeleton and `pubspec.yaml`.

   Example `pubspec.yaml`:

```yaml
name: file_picker_platform_interface
version: 1.0.0
description: Platform interface for file_picker plugin.
publish_to: none

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  plugin_platform_interface: ^2.1.8
  flutter:
    sdk: flutter

flutter:
  plugin:
    platforms: {}
```

2. Move `lib/src/platform/file_picker_platform_interface.dart` into this package as
   `lib/src/...` and add a public export `lib/file_picker_platform_interface.dart`.

3. Update all implementations (web, android, ios, desktop) to import
   `package:file_picker_platform_interface/file_picker_platform_interface.dart`.

4. Update the root `file_picker` package to depend on the new interface package
   (replace direct references to the moved file with `package:` imports).

5. Run tests and CI, publish packages if desired.

Notes:
- Keep a clear migration commit that moves the interface first and then rewires implementations.
- If you want a safer short-term approach, keep a public `lib/file_picker_platform_interface.dart`
  in the root (already present) until all implementations are migrated.

---
Created to hold extraction notes so we can extract the interface cleanly later.
