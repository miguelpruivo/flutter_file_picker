package com.mr.flutter.plugin.filepicker

import android.net.Uri

class FileInfo(
    val path: String?,
    val name: String?,
    val uri: Uri?,
    val size: Long,
    val bytes: ByteArray?,
    val safHandle: java.util.HashMap<String, Any>? = null
) {
    class Builder {
        private var path: String? = null
        private var name: String? = null
        private var uri: Uri? = null
        private var size: Long = 0
        private var bytes: ByteArray? = null
        private var safHandle: java.util.HashMap<String, Any>? = null

        fun withPath(path: String?): Builder {
            this.path = path
            return this
        }

        fun withName(name: String?): Builder {
            this.name = name
            return this
        }

        fun withSize(size: Long): Builder {
            this.size = size
            return this
        }

        fun withData(bytes: ByteArray): Builder {
            this.bytes = bytes
            return this
        }

        fun withUri(uri: Uri?): Builder {
            this.uri = uri
            return this
        }

        fun withSafHandle(safHandle: java.util.HashMap<String, Any>?): Builder {
            this.safHandle = safHandle
            return this
        }

        fun build(): FileInfo {
            return FileInfo(
                this.path,
                this.name,
                this.uri,
                this.size,
                this.bytes,
                this.safHandle
            )
        }
    }

    fun toMap(): HashMap<String, Any?> {
        // NOTE: bytes are intentionally NOT sent over the method channel.
        // Serialising large byte arrays via StandardMethodCodec blocks the
        // platform (UI) thread for the full duration of the copy, causing
        // visible freezes for files larger than a few MB.
        // Instead, the file is already cached on disk (see openFileStream) and
        // Dart reads the bytes from the cache path using a background isolate
        // when withData == true (see MethodChannelFilePicker._getPath).
        return hashMapOf<String, Any?>(
            Pair("path", path),
            Pair("name", name),
            Pair("size", size),
            Pair("bytes", null),
            Pair("identifier", uri.toString()),
            Pair("safHandle", safHandle)
        )
    }
}
