package file_picker

import (
	"strings"

	"github.com/pkg/errors"
)

func fileFilter(method string) (string, error) {
	var filter string

	switch method {
	case "ANY":
		filter = "*"
	case "IMAGE":
		filter = "Images (*.jpeg,*.png,*.gif)\x00*.jpg;*.jpeg;*.png;*.gif\x00All Files (*.*)\x00*.*\x00\x00"
	case "AUDIO":
		filter = "Audios (*.mp3)\x00*.mp3\x00All Files (*.*)\x00*.*\x00\x00"
	case "VIDEO":
		filter = "Videos (*.webm,*.wmv,*.mpeg,*.mkv,*.mp4,*.avi,*.mov,*.flv)\x00*.webm;*.wmv;*.mpeg;*.mkv;*mp4;*.avi;*.mov;*.flv\x00All Files (*.*)\x00*.*\x00\x00"
	default:
		if strings.HasPrefix(method, "__CUSTOM_") {
			resolveType := strings.Split(method, "__CUSTOM_")
			filter = "Files (*." + resolveType[1] + ")\x00*." + resolveType[1] + "\x00All Files (*.*)\x00*.*\x00\x00"
		} else {
			return "", errors.New("unknown method")
		}
	}

	return filter, nil

}
