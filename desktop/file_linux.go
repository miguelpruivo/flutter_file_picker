package file_picker

import (
	"fmt"
	"strings"

	"github.com/pkg/errors"
)

func fileFilter(method string) (string, error) {
	var filter string

	switch method {
	case "ANY":
		filter = `*.*`
	case "IMAGE":
		filter = `*.png *.jpg *.jpeg`
	case "AUDIO":
		filter = `*.mp3`
	case "VIDEO":
		filter = `*.webm *.mpeg *.mkv *.mp4 *.avi *.mov *.flv`
	default:
		if strings.HasPrefix(method, "__CUSTOM_") {
			resolveType := strings.Split(method, "__CUSTOM_")
			filter = `*.` + resolveType[1]			
		} else {
			return "", errors.New("unknown method")
		}
	}

	return filter, nil

}
