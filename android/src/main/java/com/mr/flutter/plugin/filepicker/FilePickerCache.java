package com.mr.flutter.plugin.filepicker;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

class FilePickerCache {

    static final String MAP_KEY_PATHS = "paths";
    static final String MAP_KEY_ERROR_CODE = "errorCode";
    static final String MAP_KEY_ERROR_MESSAGE = "errorMessage";

    private static final String FLUTTER_FILE_PICKER_FILES_PATH_KEY =
            "flutter_file_picker_files_path";
    private static final String SHARED_PREFERENCE_ERROR_CODE_KEY = "flutter_file_picker_error_code";
    private static final String SHARED_PREFERENCE_ERROR_MESSAGE_KEY =
            "flutter_file_picker_error_message";
    private static final String SHARED_PREFERENCE_LOAD_DATA_KEY =
            "flutter_file_picker_load_data";
    private static final String SHARED_PREFERENCE_TYPE_KEY =
            "flutter_file_picker_type";

    static final String SHARED_PREFERENCES_NAME = "flutter_file_picker_shared_preference";

    final private SharedPreferences prefs;

    FilePickerCache(Context context) {
        prefs = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
    }

    public void saveLoadDataToMemory(boolean loadDataToMemory) {
        prefs.edit().putBoolean(SHARED_PREFERENCE_LOAD_DATA_KEY, loadDataToMemory).apply();
    }

    Boolean retrieveLoadDataToMemory() {
        return prefs.getBoolean(SHARED_PREFERENCE_LOAD_DATA_KEY, false);
    }

    public void saveType(String type) {
        prefs.edit().putString(SHARED_PREFERENCE_TYPE_KEY, type).apply();
    }

    String retrieveType() {
        return prefs.getString(SHARED_PREFERENCE_TYPE_KEY, "");
    }

    void saveResult(
            @Nullable Intent data,
            @Nullable String errorCode,
            @Nullable String errorMessage
    ) {
        SharedPreferences.Editor editor = prefs.edit();
        if (data != null) {
          HashSet<String> uris = new HashSet<String>();
          if (data.getClipData() != null) {
                final int count = data.getClipData().getItemCount();
                int currentItem = 0;
                while (currentItem < count) {
                    final Uri currentUri = data.getClipData().getItemAt(currentItem).getUri();
                    uris.add(currentUri.toString());
                    currentItem++;
                }
            }
            if (data.getData() != null) {
                Uri uri = data.getData();
                uris.add(uri.toString());
            }

            if (!uris.isEmpty()) {
              editor.putStringSet(FLUTTER_FILE_PICKER_FILES_PATH_KEY, uris);
            } else {
              saveResult(null,"unknown_path", "Failed to retrieve path.");
            }
        }
        if (errorCode != null) {
            editor.putString(SHARED_PREFERENCE_ERROR_CODE_KEY, errorCode);
        }
        if (errorMessage != null) {
            editor.putString(SHARED_PREFERENCE_ERROR_MESSAGE_KEY, errorMessage);
        }
        editor.apply();
    }

    Map<String, Object> getCacheMap() {

        Map<String, Object> resultMap = new HashMap<>();

        if (prefs.contains(FLUTTER_FILE_PICKER_FILES_PATH_KEY)) {
            final Set<String> paths = prefs.getStringSet(FLUTTER_FILE_PICKER_FILES_PATH_KEY, new HashSet<String>());
            resultMap.put(MAP_KEY_PATHS, paths);
        }

        if (prefs.contains(SHARED_PREFERENCE_ERROR_CODE_KEY)) {
            final String errorCodeValue = prefs.getString(SHARED_PREFERENCE_ERROR_CODE_KEY, "");
            resultMap.put(MAP_KEY_ERROR_CODE, errorCodeValue);
            if (prefs.contains(SHARED_PREFERENCE_ERROR_MESSAGE_KEY)) {
                final String errorMessageValue = prefs.getString(SHARED_PREFERENCE_ERROR_MESSAGE_KEY, "");
                resultMap.put(MAP_KEY_ERROR_MESSAGE, errorMessageValue);
            }
        }

        return resultMap;
    }


    void clear() {
        prefs.edit().clear().apply();
    }
}