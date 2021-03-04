package com.mr.flutter.plugin.filepicker;

import java.util.HashMap;

public class FileEvent {

    final String type;
    final Object value;

    public FileEvent(String type, Object value) {
        this.type = type;
        this.value = value;
    }

    public HashMap<String, Object> toMap() {
        final HashMap<String, Object> data = new HashMap<>();
        data.put("type", type);
        data.put("value", value);
        return data;
    }
}