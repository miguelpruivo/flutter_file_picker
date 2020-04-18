package file_picker

import (
	"strings"

	"github.com/gen2brain/dlgs"
	"github.com/pkg/errors"
)

func fileFilter(method string, extensions []string, size int, isMulti bool) (string, error) {
	switch method {
	case "ANY":
		return "*", nil
	case "IMAGE":
		return "Images (*.jpeg,*.png,*.gif)\x00*.jpg;*.jpeg;*.png;*.gif\x00All Files (*.*)\x00*.*\x00\x00", nil
	case "AUDIO":
		return "Audios (*.mp3)\x00*.mp3\x00All Files (*.*)\x00*.*\x00\x00", nil
	case "VIDEO":
		return "Videos (*.webm,*.wmv,*.mpeg,*.mkv,*.mp4,*.avi,*.mov,*.flv)\x00*.webm;*.wmv;*.mpeg;*.mkv;*mp4;*.avi;*.mov;*.flv\x00All Files (*.*)\x00*.*\x00\x00", nil
	case "CUSTOM":
		var i int
		var filters = "Files ("
		for i = 0 ; i<size ; i++ {
			  filters += `*.` + extensions[i] + `,`
		}
		filters += ")\x00*." + resolveType[1] + "\x00All Files (*.*)\x00*.*\x00\x00"
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
