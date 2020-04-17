package file_picker

import (
	"github.com/gen2brain/dlgs"
	"github.com/pkg/errors"
)

func fileFilter(method string, extensions []string, size int, isMulti bool) (string, error) {
	switch method {
	case "ANY":
		return `*.*`, nil
	case "IMAGE":
		return `*.png *.jpg *.jpeg`, nil
	case "AUDIO":
		return `*.mp3 *.wav *.midi *.ogg *.aac`, nil
	case "VIDEO":
		return `*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv`, nil
	case "CUSTOM":
		var i int
		var filters = ""
		for i = 0; i < size; i++ {
			filters += `*.` + extensions[i] + ` `
		}
		return filters, nil
	default:
		return "", errors.New("unknown method")
	}

}

func fileDialog(title string, filter string) (string, error) {
	filePath, _, err := dlgs.File(title, filter, false)
	if err != nil {
		return "", errors.Wrap(err, "failed to open dialog picker")
	}
	return filePath, nil
}
