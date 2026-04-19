#include <flutter_linux/flutter_linux.h>

#include "include/file_picker/file_picker_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Handles the getPlatformVersion method call.
FlMethodResponse *get_platform_version();

FlMethodResponse *open_file_dialog(const char *dialog_title,
                                   const char *initial_dir, const char *type,
                                   const char *allowed_extensions,
                                   bool allow_multiple, bool file_only);

FlMethodResponse *open_folder_dialog(const char *dialog_title,
                                     const char *initial_dir,
                                     bool allow_multiple);

FlMethodResponse *save_file_dialog(const char *dialog_title,
                                   const char *initial_dir,
                                   const char *file_name);
