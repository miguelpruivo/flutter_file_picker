package file_picker

import (
	"strings"

	"github.com/pkg/errors"
)

func fileFilter(method string) (string, error) {
	var filter string

	switch method {
	case "ANY":
		filter = `public.item`
	case "IMAGE":
		filter = `public.image`
	case "AUDIO":
		filter = `public.audio`
	case "VIDEO":
		filter = `public.movie`
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
