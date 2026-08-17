## 1.0.2

#### Desktop (Windows)

- Fix saved files missing their extension when the user types a file name without one: set `lpstrDefExt` on `OPENFILENAMEW` so Windows appends the default extension (derived from the allowed extensions or the suggested file name). Fixes [#2139](https://github.com/miguelpruivo/flutter_file_picker/issues/2139).

## 1.0.1

- Improved package description, added example, and added missing API documentation.

## 1.0.0

- Initial release of Windows implementation package for `file_picker`.
