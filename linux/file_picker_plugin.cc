#include "include/file_picker/file_picker_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#include "file_picker_plugin_private.h"

static GtkWindow *window = NULL;

#define FILE_PICKER_PLUGIN(obj)                                                \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), file_picker_plugin_get_type(),            \
                              FilePickerPlugin))

struct _FilePickerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FilePickerPlugin, file_picker_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void file_picker_plugin_handle_method_call(FilePickerPlugin *self,
                                                  FlMethodCall *method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *value = fl_method_call_get_args(method_call);
  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "pickDirectoryPaths") == 0) {
    const gchar *dialogTitle =
        fl_value_get_string(fl_value_get_map_value(value, 0));

    const gchar *initialDirectory =
        fl_value_get_string(fl_value_get_map_value(value, 1));
    const gboolean allowMultiple =
        fl_value_get_bool(fl_value_get_map_value(value, 2));
    response = open_folder_dialog(dialogTitle, initialDirectory, allowMultiple);
  } else if (strcmp(method, "pickFiles") == 0) {
    const gchar *dialogTitle =
        fl_value_get_string(fl_value_get_map_value(value, 0));
    const gchar *initialDirectory =
        fl_value_get_string(fl_value_get_map_value(value, 1));
    const gchar *type = fl_value_get_string(fl_value_get_map_value(value, 2));
    const gchar *allowedExtensions =
        fl_value_get_string(fl_value_get_map_value(value, 3));
    bool allowMultiple = fl_value_get_bool(fl_value_get_map_value(value, 4));
    bool fileOnly = fl_value_get_bool(fl_value_get_map_value(value, 5));
    response = open_file_dialog(dialogTitle, initialDirectory, type,
                                allowedExtensions, allowMultiple, fileOnly);
  } else if (strcmp(method, "saveFile") == 0) {
    const gchar *dialogTitle =
        fl_value_get_string(fl_value_get_map_value(value, 0));
    const gchar *initialDirectory =
        fl_value_get_string(fl_value_get_map_value(value, 1));
    const gchar *fileName =
        fl_value_get_string(fl_value_get_map_value(value, 2));
    response = save_file_dialog(dialogTitle, initialDirectory, fileName);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse *get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void file_picker_plugin_dispose(GObject *object) {
  G_OBJECT_CLASS(file_picker_plugin_parent_class)->dispose(object);
}

static void file_picker_plugin_class_init(FilePickerPluginClass *klass) {
  G_OBJECT_CLASS(klass)->dispose = file_picker_plugin_dispose;
}

static void file_picker_plugin_init(FilePickerPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data) {
  FilePickerPlugin *plugin = FILE_PICKER_PLUGIN(user_data);
  file_picker_plugin_handle_method_call(plugin, method_call);
}

static GtkFileChooserNative *
create_file_chooser_native(const char *dialog_title,
                           GtkFileChooserAction action) {
  return gtk_file_chooser_native_new(dialog_title, window, action, NULL, NULL);
}

void file_picker_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
  FilePickerPlugin *plugin =
      FILE_PICKER_PLUGIN(g_object_new(file_picker_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "miguelruivo.flutter.plugins.filepicker", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  FlView *view = fl_plugin_registrar_get_view(registrar);
  if (view != NULL) {
    GtkWidget *toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
    if (GTK_IS_WINDOW(toplevel)) {
      window = GTK_WINDOW(toplevel);
    }
  }

  g_object_unref(plugin);
}

FlMethodResponse *open_file_dialog(const char *dialog_title,
                                   const char *initial_dir, const char *type,
                                   const char *allowed_extensions,
                                   bool allow_multiple, bool file_only) {
  GtkFileChooserNative *dialog =
      create_file_chooser_native(dialog_title, GTK_FILE_CHOOSER_ACTION_OPEN);
  GtkFileChooser *chooser = GTK_FILE_CHOOSER(dialog);
  gtk_file_chooser_set_select_multiple(chooser, allow_multiple);
  if (initial_dir != NULL && g_file_test(initial_dir, G_FILE_TEST_IS_DIR)) {
    gtk_file_chooser_set_current_folder(chooser, initial_dir);
  }

  GtkFileFilter *filter = gtk_file_filter_new();

  if (g_strcmp0(type, "any") == 0) {
    gtk_file_filter_set_name(filter, "All Files");
    gtk_file_filter_add_pattern(filter, "*");
  } else if (g_strcmp0(type, "image") == 0) {
    gtk_file_filter_set_name(filter, "Image Files");
    gtk_file_filter_add_mime_type(filter, "image/png");
    gtk_file_filter_add_mime_type(filter, "image/jpeg");
    gtk_file_filter_add_mime_type(filter, "image/gif");
    gtk_file_filter_add_mime_type(filter, "image/webp");
    gtk_file_filter_add_pattern(filter, "*.png");
    gtk_file_filter_add_pattern(filter, "*.jpg");
    gtk_file_filter_add_pattern(filter, "*.jpeg");
    gtk_file_filter_add_pattern(filter, "*.gif");
    gtk_file_filter_add_pattern(filter, "*.webp");
  } else if (g_strcmp0(type, "video") == 0) {
    gtk_file_filter_set_name(filter, "Video Files");
    gtk_file_filter_add_pattern(filter, "*.mp4");
    gtk_file_filter_add_pattern(filter, "*.mkv");
    gtk_file_filter_add_pattern(filter, "*.avi");
    gtk_file_filter_add_pattern(filter, "*.mov");
    gtk_file_filter_add_pattern(filter, "*.webm");
  } else if (g_strcmp0(type, "audio") == 0) {
    gtk_file_filter_set_name(filter, "Audio Files");
    gtk_file_filter_add_pattern(filter, "*.mp3");
    gtk_file_filter_add_pattern(filter, "*.wav");
    gtk_file_filter_add_pattern(filter, "*.flac");
    gtk_file_filter_add_pattern(filter, "*.ogg");
    gtk_file_filter_add_pattern(filter, "*.m4a");
    gtk_file_filter_add_pattern(filter, "*.aac");
  } else if (g_strcmp0(type, "media") == 0) {
    gtk_file_filter_set_name(filter, "Media Files");
    gtk_file_filter_add_pattern(filter, "*.png");
    gtk_file_filter_add_pattern(filter, "*.jpg");
    gtk_file_filter_add_pattern(filter, "*.jpeg");
    gtk_file_filter_add_pattern(filter, "*.gif");
    gtk_file_filter_add_pattern(filter, "*.webp");
    gtk_file_filter_add_pattern(filter, "*.mp4");
    gtk_file_filter_add_pattern(filter, "*.mkv");
    gtk_file_filter_add_pattern(filter, "*.avi");
    gtk_file_filter_add_pattern(filter, "*.mov");
    gtk_file_filter_add_pattern(filter, "*.webm");
  } else if (g_strcmp0(type, "custom") == 0) {
    gtk_file_filter_set_name(filter, "Custom Files");
    g_autofree gchar **custom_extensions =
        g_strsplit(allowed_extensions, ",", 0);
    int custom_count = g_strv_length(custom_extensions);

    for (int i = 0; i < custom_count; i++) {
      char pattern[64];
      g_snprintf(pattern, sizeof(pattern), "*.%s", custom_extensions[i]);
      gtk_file_filter_add_pattern(filter, pattern);
    }
  } else {
    gtk_file_filter_set_name(filter, "All Files");
    gtk_file_filter_add_pattern(filter, "*");
  }

  gtk_file_chooser_add_filter(chooser, filter);

  g_autoptr(FlValue) result = nullptr;
  gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(dialog));
  if (res == GTK_RESPONSE_ACCEPT) {
    // char *filename = gtk_file_chooser_get_filename(chooser);
    // if (filename != NULL) {
    //   selected_file = g_strdup(filename);
    //   g_free(filename);
    //   result = fl_value_new_string(selected_file);
    // }
    GSList *files = gtk_file_chooser_get_filenames(chooser);
    result = fl_value_new_list();
    for (GSList *iter = files; iter != NULL; iter = iter->next) {
      char *filename = (char *)iter->data;
      if (filename != NULL) {
        // printf("filename: %s\n", filename);
        if (file_only) {
          if (g_file_test(filename, G_FILE_TEST_IS_REGULAR)) {
            fl_value_append_take(result, fl_value_new_string(filename));
          }
        } else {
          fl_value_append_take(result, fl_value_new_string(filename));
        }
      }
      g_free(filename);
    }
    g_slist_free(files);
  }
  g_object_unref(dialog);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse *open_folder_dialog(const char *dialog_title,
                                     const char *initial_dir,
                                     bool allow_multiple) {
  GtkFileChooserNative *dialog = create_file_chooser_native(
      dialog_title, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
  GtkFileChooser *chooser = GTK_FILE_CHOOSER(dialog);

  if (initial_dir != NULL && g_file_test(initial_dir, G_FILE_TEST_IS_DIR)) {
    gtk_file_chooser_set_current_folder(chooser, initial_dir);
  }
  gtk_file_chooser_set_select_multiple(chooser, allow_multiple);

  g_autoptr(FlValue) result = nullptr;
  gint res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(dialog));
  if (res == GTK_RESPONSE_ACCEPT) {
    result = fl_value_new_list();
    GSList *files = gtk_file_chooser_get_filenames(chooser);
    for (GSList *iter = files; iter != NULL; iter = iter->next) {
      char *filename = (char *)iter->data;
      if (filename != NULL) {
        // printf("filename: %s\n", filename);
        fl_value_append_take(result, fl_value_new_string(filename));
      }
      g_free(filename);
    }
    g_slist_free(files);
  }
  g_object_unref(dialog);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse *save_file_dialog(const char *dialog_title,
                                   const char *initial_dir,
                                   const char *file_name) {
  GtkFileChooserNative *dialog =
      create_file_chooser_native(dialog_title, GTK_FILE_CHOOSER_ACTION_SAVE);
  GtkFileChooser *chooser = GTK_FILE_CHOOSER(dialog);
  if (initial_dir != NULL && g_file_test(initial_dir, G_FILE_TEST_IS_DIR)) {
    gtk_file_chooser_set_current_folder(chooser, initial_dir);
  }
  gtk_file_chooser_set_current_name(chooser, file_name);
  gtk_file_chooser_set_do_overwrite_confirmation(chooser, TRUE);

  g_autoptr(FlValue) result = nullptr;
  if (gtk_native_dialog_run(GTK_NATIVE_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
    char *filename = gtk_file_chooser_get_filename(chooser);
    result = fl_value_new_string(filename);
    g_free(filename);
  }

  g_object_unref(dialog);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}
