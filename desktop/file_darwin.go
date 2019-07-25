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
		filter = `"*"`
	case "IMAGE":
		filter = `"PNG", "public.png", "JPEG", "jpg", "public.jpeg"`
	case "AUDIO":
		filter = `"MP3", "public.mp3"`
	case "VIDEO":
		filter = `"MOV"`
	default:
		if strings.HasPrefix(method, "__CUSTOM_") {
			resolveType := strings.Split(method, "__CUSTOM_")
			filter = `"` + resolveType[1] + `"`			
		} else {
			return "", errors.New("unknown method")
		}
	}

	return filter, nil

}
