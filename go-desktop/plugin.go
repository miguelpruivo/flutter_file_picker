package file_picker

import (
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/pkg/errors"
)

const channelName = "file_picker"

type FilePickerPlugin struct{}

var _ flutter.Plugin = &FilePickerPlugin{} // compile-time type check

func (p *FilePickerPlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.StandardMethodCodec{})
	channel.CatchAllHandleFunc(p.handleFilePicker)
	return nil
}

func (p *FilePickerPlugin) handleFilePicker(methodCall interface{}) (reply interface{}, err error) {
	method := methodCall.(plugin.MethodCall)
	multipleSelection := method.Arguments.(bool)

	filter, err := fileFilter(method.Method)
	if err != nil {
		return nil, errors.Wrap(err, "failed to get filter")
	}

	dialogProvider := dialogProvider{}
	fileDescriptor, err := p.filePicker(dialogProvider, false, filter, multipleSelection)
	if err != nil {
		return "", errors.Wrap(err, "user cancel select file")
	}

	return fileDescriptor, nil
}

func (p *FilePickerPlugin) filePicker(dialog dialog, isDirectory bool, filter string, multipleSelection bool) (reply interface{}, err error) {
	switch multipleSelection {
	case false:
		fileDescriptor, _, err := dialog.File("select file", filter, isDirectory)
		if err != nil {
			return nil, errors.Wrap(err, "failed to open dialog picker")
		}
		return fileDescriptor, nil

	case true:
		fileDescriptors, _, err := dialog.FileMulti("select files", filter)
		if err != nil {
			return nil, errors.Wrap(err, "failed to open dialog picker")
		}

		//type []string is not supported by StandardMessageCodec
		sliceFileDescriptors := make([]interface{}, len(fileDescriptors))
		for i, file := range fileDescriptors {
			sliceFileDescriptors[i] = file
		}

		return sliceFileDescriptors, nil

	default:
		fileDescriptor, _, err := dialog.File("select file", filter, isDirectory)
		if err != nil {
			return nil, errors.Wrap(err, "failed to open dialog picker")
		}
		return fileDescriptor, nil
	}

}
