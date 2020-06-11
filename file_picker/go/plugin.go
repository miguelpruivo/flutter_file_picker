package file_picker

import (
	"github.com/gen2brain/dlgs"
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/pkg/errors"
)

const channelName = "miguelruivo.flutter.plugins.filepicker"

type FilePickerPlugin struct{}

var _ flutter.Plugin = &FilePickerPlugin{} // compile-time type check

func (p *FilePickerPlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.StandardMethodCodec{})
	channel.CatchAllHandleFunc(p.handleFilePicker)
	return nil
}

func (p *FilePickerPlugin) handleFilePicker(methodCall interface{}) (reply interface{}, err error) {
	method := methodCall.(plugin.MethodCall).Method
	arguments := methodCall.(plugin.MethodCall).Arguments.(map[interface{}]interface{})
	var allowedExtensions []string

	// Parse extensions
	if arguments != nil && arguments["allowedExtensions"] != nil {
		allowedExtensions = make([]string, len(arguments["allowedExtensions"].([]interface{})))
		for i := range arguments["allowedExtensions"].([]interface{}) {
			allowedExtensions[i] = arguments["allowedExtensions"].([]interface{})[i].(string)
		}
	}

	selectMultiple, ok := arguments["allowMultipleSelection"].(bool) //method.Arguments.(bool)
	if !ok {
		return nil, errors.Wrap(err, "invalid format for argument, not a bool")
	}

	filter, err := fileFilter(method, allowedExtensions, len(allowedExtensions), selectMultiple)
	if err != nil {
		return nil, errors.Wrap(err, "failed to get filter")
	}

	if selectMultiple {
		filePaths, _, err := dlgs.FileMulti("Select one or more files", filter)
		if err != nil {
			return nil, errors.Wrap(err, "failed to open dialog picker")
		}

		// type []string is not supported by StandardMessageCodec
		sliceFilePaths := make([]interface{}, len(filePaths))
		for i, file := range filePaths {
			sliceFilePaths[i] = file
		}

		return sliceFilePaths, nil
	}

	filePath, err := fileDialog("Select a file", filter)
	if err != nil {
		return nil, errors.Wrap(err, "failed to open dialog picker")
	}
	return filePath, nil
}
