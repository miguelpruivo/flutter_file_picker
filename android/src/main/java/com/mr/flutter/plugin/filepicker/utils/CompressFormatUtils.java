package com.mr.flutter.plugin.filepicker.utils;

import android.graphics.Bitmap;

public class CompressFormatUtils {

    public static Bitmap.CompressFormat getFileExtension(String format) {
        switch (format.toUpperCase()) {
            case "PNG":
                return Bitmap.CompressFormat.PNG;
            case "WEBP":
                return Bitmap.CompressFormat.WEBP;
            default:
                return Bitmap.CompressFormat.JPEG;
        }
    }
}