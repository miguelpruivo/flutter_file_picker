package com.mr.flutter.plugin.filepicker;

import android.net.Uri;

import java.util.HashMap;

public class FileInfo {

    final Uri uri;
    final String path;
    final String name;
    final int size;
    final byte[] bytes;
    final long lastModified;
    final boolean isDirectory;

    public FileInfo(Uri uri, String path, String name, int size, byte[] bytes, boolean isDirectory, long lastModified) {
        this.uri = uri;
        this.path = path;
        this.name = name;
        this.size = size;
        this.bytes = bytes;
        this.lastModified = lastModified;
        this.isDirectory = isDirectory;
    }

    public static class Builder {

        private Uri uri;
        private String path;
        private String name;
        private int size;
        private long lastModified;
        private byte[] bytes;
        private boolean isDirectory;

        public Builder withUri(Uri uri){
            this.uri = uri;
            return this;
        }

        public Builder withPath(String path){
            this.path = path;
            return this;
        }

        public Builder withName(String name){
            this.name = name;
            return this;
        }

        public Builder withSize(int size){
            this.size = size;
            return this;
        }

        public Builder withData(byte[] bytes){
            this.bytes = bytes;
            return this;
        }

        public Builder withDirectory(String path){
            this.path = path;
            this.isDirectory = path != null;
            return this;
        }

        public Builder lastModifiedAt(long timeStamp){
            this.lastModified = timeStamp;
            return this;
        }

        public FileInfo build() {
            return new FileInfo(this.uri, this.path, this.name, this.size, this.bytes, this.isDirectory, this.lastModified);
        }
    }


    public HashMap<String, Object> toMap() {
        final HashMap<String, Object> data = new HashMap<>();
        data.put("uri", uri.toString());
        data.put("path", path);
        data.put("name", name);
        data.put("size", size);
        data.put("bytes", bytes);
        data.put("isDirectory", isDirectory);
        data.put("lastModified", lastModified);
        return data;
    }
}
