# file_picker

This Go package implements the host-side of the Flutter [file_picker](https://github.com/miguelpruivo/plugins_flutter_file_picker) plugin.

## Usage

Import as:

```go
import "github.com/miguelpruivo/plugins_flutter_file_picker/desktop"
```

Then add the following option to your go-flutter [application options](https://github.com/go-flutter-desktop/go-flutter/blob/68868301742b864b719b31ae51c7ec4b3b642d1a/example/simpleDemo/main.go#L53):

```go
flutter.AddPlugin(&file_picker.FilePickerPlugin{}),
```

## Issues

Please report issues at the [go-flutter issue tracker](https://github.com/go-flutter-desktop/go-flutter/issues/).
