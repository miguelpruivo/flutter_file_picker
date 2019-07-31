package file_picker

import "github.com/gen2brain/dlgs"

type dialog interface {
	File(title string, filter string, directory bool) (string, bool, error)
	FileMulti(title, filter string) ([]string, bool, error)
}

type dialogProvider struct {}

func (dialog dialogProvider) File(title string, filter string, directory bool) (string, bool, error) {
	return dlgs.File(title, filter, directory)
}

func (dialog dialogProvider) FileMulti(title, filter string) ([]string, bool, error) {
	return dlgs.FileMulti(title, filter)
}
