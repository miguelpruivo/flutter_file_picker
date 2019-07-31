package main

import (
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/chunhunghan/plugins_flutter_file_picker/go-desktop"
)

var options = []flutter.Option{
	flutter.WindowInitialDimensions(800, 1280),
	flutter.AddPlugin(&file_picker.FilePickerPlugin{}),
}
