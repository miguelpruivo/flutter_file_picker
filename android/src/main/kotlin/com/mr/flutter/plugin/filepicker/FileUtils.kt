package com.mr.flutter.plugin.filepicker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object FileUtils {
    private const val TAG = "FilePickerUtils"
    private const val PRIMARY_VOLUME_NAME = "primary"

    fun getMimeTypes(allowedExtensions: ArrayList<String>?): ArrayList<String?>? {
        if (allowedExtensions == null || allowedExtensions.isEmpty()) {
            return null
        }

        val mimes = ArrayList<String?>()

        for (i in allowedExtensions.indices) {
            val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(
                allowedExtensions[i]
            )
            if (mime == null) {
                Log.w(
                    TAG,
                    "Custom file type " + allowedExtensions[i] + " is unsupported and will be ignored."
                )
                continue
            }

            mimes.add(mime)
        }
        Log.d(
            TAG,
            "Allowed file extensions mimes: $mimes"
        )
        return mimes
    }

    @JvmStatic
    fun getFileName(uri: Uri, context: Context): String? {
        var result: String? = null

        try {
            if (uri.scheme == "content") {
                context.contentResolver.query(
                    uri,
                    arrayOf(OpenableColumns.DISPLAY_NAME),
                    null,
                    null,
                    null
                ).use { cursor ->
                    if (cursor != null && cursor.moveToFirst()) {
                        result =
                            cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                    }
                }
            }
            if (result == null) {
                result = uri.path?.substringAfterLast('/')
            }
        } catch (ex: Exception) {
            Log.e(
                TAG,
                "Failed to handle file name: $ex"
            )
        }

        return result
    }

    @JvmStatic
    fun isImage(context: Context, uri: Uri): Boolean {
        val extension = getFileExtension(context, uri)
        return (extension != null && (extension.contentEquals("jpg") || extension.contentEquals("jpeg") || extension.contentEquals(
            "png"
        ) || extension.contentEquals("WEBP")))
    }

    private fun getFileExtension(context: Context, uri: Uri): String? {
        val contentResolver = context.contentResolver
        val mimeType = contentResolver.getType(uri)
        return MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
    }

    private fun getCompressFormat(context: Context, uri: Uri): Bitmap.CompressFormat {
        val format = getFileExtension(context, uri)
        return when (format!!.uppercase(Locale.getDefault())) {
            "PNG" -> Bitmap.CompressFormat.PNG
            "WEBP" -> Bitmap.CompressFormat.WEBP
            else -> Bitmap.CompressFormat.JPEG
        }
    }

    @JvmStatic
    fun compressImage(originalImageUri: Uri, compressionQuality: Int, context: Context): Uri {
        val compressedUri: Uri
        try {
            context.contentResolver.openInputStream(originalImageUri).use { imageStream ->
                val compressedFile = createImageFile(context, originalImageUri)
                val originalBitmap = BitmapFactory.decodeStream(imageStream)
                // Compress and save the image
                val fos = FileOutputStream(compressedFile)
                originalBitmap.compress(
                    getCompressFormat(context, originalImageUri),
                    compressionQuality,
                    fos
                )
                fos.flush()
                fos.close()
                compressedUri = Uri.fromFile(compressedFile)
            }
        } catch (e: IOException) {
            throw RuntimeException(e)
        }
        return compressedUri
    }

    @Throws(IOException::class)
    private fun createImageFile(context: Context, uri: Uri): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val imageFileName = "IMAGE_" + timeStamp + "_"
        val storageDir = context.cacheDir
        return File.createTempFile(imageFileName, "." + getFileExtension(context, uri), storageDir)
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    @JvmStatic
    fun clearCache(context: Context): Boolean {
        try {
            val cacheDir = File(context.cacheDir.toString() + "/file_picker/")
            recursiveDeleteFile(cacheDir)
        } catch (ex: Exception) {
            Log.e(
                TAG,
                "There was an error while clearing cached files: $ex"
            )
            return false
        }
        return true
    }

    fun loadData(file: File, fileInfo: FileInfo.Builder) {
        try {
            val size = file.length().toInt()
            val bytes = ByteArray(size)

            try {
                val buf = BufferedInputStream(FileInputStream(file))
                buf.read(bytes, 0, bytes.size)
                buf.close()
            } catch (e: FileNotFoundException) {
                Log.e(TAG, "File not found: " + e.message, null)
            } catch (e: IOException) {
                Log.e(TAG, "Failed to close file streams: " + e.message, null)
            }
            fileInfo.withData(bytes)
        } catch (e: Exception) {
            Log.e(
                TAG,
                "Failed to load bytes into memory with error $e. Probably the file is too big to fit device memory. Bytes won't be added to the file this time."
            )
        }
    }

    @JvmStatic
    fun openFileStream(context: Context, uri: Uri, withData: Boolean): FileInfo? {
        Log.i(TAG, "Caching from URI: $uri")
        var fos: FileOutputStream? = null
        var `in`: InputStream? = null
        val fileInfo = FileInfo.Builder()
        val fileName = getFileName(uri, context)
        val path =
            context.cacheDir.absolutePath + "/file_picker/" + System.currentTimeMillis() + "/" + (fileName
                ?: "unamed")

        val file = File(path)

        if (!file.exists()) {
            try {
                file.parentFile?.mkdirs()
                fos = FileOutputStream(path)
                try {
                    val out = BufferedOutputStream(fos)
                    `in` = context.contentResolver.openInputStream(uri)

                    val buffer = ByteArray(8192)
                    var len = 0

                    while ((`in`!!.read(buffer).also { len = it }) >= 0) {
                        out.write(buffer, 0, len)
                    }

                    out.flush()
                } finally {
                    fos.fd.sync()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to retrieve path: " + e.message, null)
                return null
            } finally {
                if (fos != null) {
                    try {
                        fos.close()
                    } catch (ex: IOException) {
                        Log.e(TAG, "Failed to close file streams: " + ex.message, null)
                    }
                }
                if (`in` != null) {
                    try {
                        `in`.close()
                    } catch (ex: IOException) {
                        Log.e(TAG, "Failed to close file streams: " + ex.message, null)
                    }
                }
            }
        }

        Log.d(
            TAG,
            "File loaded and cached at:$path"
        )

        if (withData) {
            loadData(file, fileInfo)
        }

        fileInfo
            .withPath(path)
            .withName(fileName)
            .withUri(uri)
            .withSize(file.length().toString().toLong())

        return fileInfo.build()
    }

    @JvmStatic
    fun getFullPathFromTreeUri(treeUri: Uri?, con: Context): String? {
        if (treeUri == null) {
            return null
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            if (isDownloadsDocument(treeUri)) {
                val docId = DocumentsContract.getDocumentId(treeUri)
                val extPath =
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).path
                if (docId == "downloads") {
                    return extPath
                } else if (docId.matches("^ms[df]\\:.*".toRegex())) {
                    val fileName = getFileName(treeUri, con)
                    return "$extPath/$fileName"
                } else if (docId.startsWith("raw:")) {
                    return docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }
                        .toTypedArray()[1]
                }
                return null
            }
        }

        var volumePath = getVolumePath(
            getVolumeIdFromTreeUri(
                treeUri
            ), con
        )
            ?: return File.separator

        if (volumePath.endsWith(File.separator)) volumePath =
            volumePath.substring(0, volumePath.length - 1)

        var documentPath = getDocumentPathFromTreeUri(treeUri)

        if (documentPath.endsWith(File.separator)) documentPath =
            documentPath.substring(0, documentPath.length - 1)

        return if (!documentPath.isEmpty()) {
            if (documentPath.startsWith(File.separator)) {
                volumePath + documentPath
            } else {
                volumePath + File.separator + documentPath
            }
        } else {
            volumePath
        }
    }

    private fun getDirectoryPath(
        storageVolumeClazz: Class<*>,
        storageVolumeElement: Any?
    ): String? {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
                val getPath = storageVolumeClazz.getMethod("getPath")
                return getPath.invoke(storageVolumeElement) as String
            }

            val getDirectory = storageVolumeClazz.getMethod("getDirectory")
            val f = getDirectory.invoke(storageVolumeElement) as File
            return f.path
        } catch (_: Exception) {
            return null
        }
        return null
    }

    private fun getVolumePath(volumeId: String?, context: Context): String? {
        try {
            val mStorageManager =
                context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
            val storageVolumeClazz = Class.forName("android.os.storage.StorageVolume")
            val getVolumeList = mStorageManager.javaClass.getMethod("getVolumeList")
            val getUuid = storageVolumeClazz.getMethod("getUuid")
            val isPrimary = storageVolumeClazz.getMethod("isPrimary")
            val result = getVolumeList.invoke(mStorageManager) ?: return null

            val length = java.lang.reflect.Array.getLength(result)
            for (i in 0 until length) {
                val storageVolumeElement = java.lang.reflect.Array.get(result, i)
                val uuid = getUuid.invoke(storageVolumeElement) as? String
                val primary = isPrimary.invoke(storageVolumeElement) as? Boolean

                // primary volume?
                if (primary != null && PRIMARY_VOLUME_NAME == volumeId) {
                    return getDirectoryPath(storageVolumeClazz, storageVolumeElement)
                }

                // other volumes?
                if (uuid != null && uuid == volumeId) {
                    return getDirectoryPath(storageVolumeClazz, storageVolumeElement)
                }
            }
            // not found.
            return null
        } catch (_: Exception) {
            return null
        }
    }

    private fun getVolumeIdFromTreeUri(treeUri: Uri): String? {
        val docId = DocumentsContract.getTreeDocumentId(treeUri)
        val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
        return if (split.size > 0) split[0]
        else null
    }


    private fun getDocumentPathFromTreeUri(treeUri: Uri): String {
        val docId = DocumentsContract.getTreeDocumentId(treeUri)
        val split = docId.split(":".toRegex()).dropLastWhile { it.isEmpty() }.toTypedArray()
        return if ((split.size >= 2)) split[1]
        else File.separator
    }

    private fun recursiveDeleteFile(file: File?) {
        if (file == null || !file.exists()) {
            return
        }

        if (file.listFiles() != null && file.isDirectory) {
            for (child in file.listFiles().orEmpty()) {
                recursiveDeleteFile(child)
            }
        }

        file.delete()
    }
}