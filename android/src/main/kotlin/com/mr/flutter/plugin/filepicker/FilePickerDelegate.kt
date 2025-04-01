package com.mr.flutter.plugin.filepicker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.os.Parcelable
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.VisibleForTesting
import com.mr.flutter.plugin.filepicker.FileUtils.compressImage
import com.mr.flutter.plugin.filepicker.FileUtils.getFileName
import com.mr.flutter.plugin.filepicker.FileUtils.getFullPathFromTreeUri
import com.mr.flutter.plugin.filepicker.FileUtils.isImage
import com.mr.flutter.plugin.filepicker.FileUtils.openFileStream
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File
import java.io.IOException
import androidx.core.net.toUri

class FilePickerDelegate @VisibleForTesting internal constructor(
    private val activity: Activity,
    private var pendingResult: MethodChannel.Result?
) :
    ActivityResultListener {
    private var isMultipleSelection = false
    private var loadDataToMemory = false
    private var type: String? = null
    private var compressionQuality = 0
    private var allowedExtensions: ArrayList<String?>? = null
    private var eventSink: EventSink? = null

    private var bytes: ByteArray? = null

    constructor(activity: Activity) : this(
        activity,
        null
    )

    fun setEventHandler(eventSink: EventSink?) {
        this.eventSink = eventSink
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // Save file
        if (requestCode == SAVE_FILE_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                if (data == null) {
                    return false
                }
                this.dispatchEventStatus(true)
                val uri = data.data
                if (uri != null) {
                    val path =
                        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            .absolutePath + File.separator + getFileName(
                            uri,
                            this.activity
                        )
                    try {
                        val outputStream = activity.contentResolver.openOutputStream(uri)
                        if (outputStream != null) {
                            outputStream.write(bytes)
                            outputStream.flush()
                            outputStream.close()
                        }
                        finishWithSuccess(path)
                        return true
                    } catch (e: IOException) {
                        Log.i(TAG, "Error while saving file", e)
                        finishWithError("Error while saving file", e.message)
                    }
                }
            }
            if (resultCode == Activity.RESULT_CANCELED) {
                Log.i(TAG, "User cancelled the save request")
                finishWithSuccess(null)
            }
            return false
        }

        // Pick files
        if (type == null) {
            return false
        }

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            this.dispatchEventStatus(true)

            Thread(Runnable {
                if (data != null) {
                    val files = ArrayList<FileInfo>()

                    if (data.clipData != null) {
                        val count = data.clipData!!.itemCount
                        var currentItem = 0
                        while (currentItem < count) {
                            var currentUri = data.clipData!!.getItemAt(currentItem).uri
                            if (compressionQuality > 0 && isImage(
                                    activity.applicationContext,
                                    currentUri
                                )
                            ) {
                                currentUri = compressImage(
                                    currentUri,
                                    compressionQuality,
                                    activity.applicationContext
                                )
                            }
                            val file = openFileStream(
                                this@FilePickerDelegate.activity,
                                currentUri,
                                loadDataToMemory
                            )
                            if (file != null) {
                                files.add(file)
                                Log.d(
                                    TAG,
                                    "[MultiFilePick] File #" + currentItem + " - URI: " + currentUri.path
                                )
                            }
                            currentItem++
                        }

                        finishWithSuccess(files)
                    } else if (data.data != null) {
                        var uri = data.data

                        if (compressionQuality > 0 && isImage(
                                activity.applicationContext,
                                uri!!
                            )
                        ) {
                            uri =
                                compressImage(uri, compressionQuality, activity.applicationContext)
                        }

                        if (type == "dir") {
                            uri = DocumentsContract.buildDocumentUriUsingTree(
                                uri,
                                DocumentsContract.getTreeDocumentId(uri)
                            )

                            Log.d(
                                TAG,
                                "[SingleFilePick] File URI:$uri"
                            )
                            val dirPath = getFullPathFromTreeUri(uri, activity)

                            if (dirPath != null) {
                                finishWithSuccess(dirPath)
                            } else {
                                finishWithError(
                                    "unknown_path",
                                    "Failed to retrieve directory path."
                                )
                            }
                            return@Runnable
                        }

                        val file = openFileStream(
                            this@FilePickerDelegate.activity,
                            uri!!, loadDataToMemory
                        )

                        if (file != null) {
                            files.add(file)
                        }

                        if (!files.isEmpty()) {
                            Log.d(TAG, "File path:$files")
                            finishWithSuccess(files)
                        } else {
                            finishWithError("unknown_path", "Failed to retrieve path.")
                        }
                    } else if (data.extras != null) {
                        val bundle = data.extras
                        if (bundle!!.keySet().contains("selectedItems")) {
                            val fileUris = getSelectedItems(
                                bundle
                            )

                            var currentItem = 0
                            if (fileUris != null) {
                                for (fileUri in fileUris) {
                                    if (fileUri is Uri) {
                                        val currentUri = fileUri
                                        val file = openFileStream(
                                            this@FilePickerDelegate.activity,
                                            currentUri,
                                            loadDataToMemory
                                        )

                                        if (file != null) {
                                            files.add(file)
                                            Log.d(
                                                TAG,
                                                "[MultiFilePick] File #" + currentItem + " - URI: " + currentUri.path
                                            )
                                        }
                                    }
                                    currentItem++
                                }
                            }
                            finishWithSuccess(files)
                        } else {
                            finishWithError("unknown_path", "Failed to retrieve path from bundle.")
                        }
                    } else {
                        finishWithError(
                            "unknown_activity",
                            "Unknown activity error, please fill an issue."
                        )
                    }
                } else {
                    finishWithError(
                        "unknown_activity",
                        "Unknown activity error, please fill an issue."
                    )
                }
            }).start()
            return true
        } else if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_CANCELED) {
            Log.i(TAG, "User cancelled the picker request")
            finishWithSuccess(null)
            return true
        } else if (requestCode == REQUEST_CODE) {
            finishWithError("unknown_activity", "Unknown activity error, please fill an issue.")
        }
        return false
    }

    private fun setPendingMethodCallAndResult(result: MethodChannel.Result): Boolean {
        if (this.pendingResult != null) {
            return false
        }
        this.pendingResult = result
        return true
    }

    @Suppress("deprecation")
    private fun getSelectedItems(bundle: Bundle): ArrayList<Parcelable>? {
        if (Build.VERSION.SDK_INT >= 33) {
            return bundle.getParcelableArrayList("selectedItems", Parcelable::class.java)
        }

        return bundle.getParcelableArrayList("selectedItems")
    }

    private fun startFileExplorer() {
        val intent: Intent

        // Temporary fix, remove this null-check after Flutter Engine 1.14 has landed on stable
        if (type == null) {
            return
        }

        if (type == "dir") {
            intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        } else {
            if (type == "image/*") {
                intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            } else {
                intent =
                    Intent(Intent.ACTION_OPEN_DOCUMENT)
                intent.addCategory(Intent.CATEGORY_OPENABLE)
            }
            val uri = (Environment.getExternalStorageDirectory().path + File.separator).toUri()
            Log.d(TAG, "Selected type $type")
            intent.setDataAndType(uri, this.type)
            intent.type = this.type
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, this.isMultipleSelection)
            intent.putExtra("multi-pick", this.isMultipleSelection)

            type?.takeIf { it.contains(",") }
                ?.split(",")
                ?.filter { it.isNotEmpty() }
                ?.let { allowedExtensions = ArrayList(it) }

            if (allowedExtensions != null) {
                intent.putExtra(Intent.EXTRA_MIME_TYPES, allowedExtensions)
            }
        }

        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } else {
            Log.e(
                TAG,
                "Can't find a valid activity to handle the request. Make sure you've a file explorer installed."
            )
            finishWithError("invalid_format_type", "Can't handle the provided file type.")
        }
    }

    fun startFileExplorer(
        type: String?,
        isMultipleSelection: Boolean,
        withData: Boolean,
        allowedExtensions: ArrayList<String?>?,
        compressionQuality: Int,
        result: MethodChannel.Result
    ) {
        if (!this.setPendingMethodCallAndResult(result)) {
            finishWithAlreadyActiveError(result)
            return
        }
        this.type = type
        this.isMultipleSelection = isMultipleSelection
        this.loadDataToMemory = withData
        this.allowedExtensions = allowedExtensions
        this.compressionQuality = compressionQuality

        this.startFileExplorer()
    }

    fun saveFile(
        fileName: String?,
        type: String?,
        initialDirectory: String?,
        allowedExtensions: ArrayList<String?>?,
        bytes: ByteArray?,
        result: MethodChannel.Result
    ) {
        if (!this.setPendingMethodCallAndResult(result)) {
            finishWithAlreadyActiveError(result)
            return
        }
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
        intent.addCategory(Intent.CATEGORY_OPENABLE)
        if (fileName != null && !fileName.isEmpty()) {
            intent.putExtra(Intent.EXTRA_TITLE, fileName)
        }
        this.bytes = bytes
        if (type != null && ("dir" != type) && type.split(",".toRegex())
                .dropLastWhile { it.isEmpty() }.toTypedArray().size == 1
        ) {
            intent.type = type
        } else {
            intent.type = "*/*"
        }
        if (initialDirectory != null && !initialDirectory.isEmpty()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialDirectory.toUri())
            }
        }
        if (allowedExtensions != null && allowedExtensions.isNotEmpty()) {
            intent.putExtra(Intent.EXTRA_MIME_TYPES, allowedExtensions)
        }
        if (intent.resolveActivity(activity.packageManager) != null) {
            activity.startActivityForResult(intent, SAVE_FILE_CODE)
        } else {
            Log.e(
                TAG,
                "Can't find a valid activity to handle the request. Make sure you've a file explorer installed."
            )
            finishWithError("invalid_format_type", "Can't handle the provided file type.")
        }
    }

    private fun finishWithSuccess(data: Any?) {
        var data = data
        this.dispatchEventStatus(false)

        // Temporary fix, remove this null-check after Flutter Engine 1.14 has landed on stable
        if (this.pendingResult != null) {
            if (data != null && data !is String) {
                val files = ArrayList<HashMap<String, Any?>>()

                for (file in data as ArrayList<FileInfo>) {
                    files.add(file.toMap())
                }
                data = files
            }

            pendingResult!!.success(data)
            this.clearPendingResult()
        }
    }

    private fun finishWithError(errorCode: String, errorMessage: String?) {
        if (this.pendingResult == null) {
            return
        }

        this.dispatchEventStatus(false)
        pendingResult!!.error(errorCode, errorMessage, null)
        this.clearPendingResult()
    }

    private fun dispatchEventStatus(status: Boolean) {
        if (eventSink == null || type == "dir") {
            return
        }

        object : Handler(Looper.getMainLooper()) {
            override fun handleMessage(message: Message) {
                eventSink!!.success(status)
            }
        }.obtainMessage().sendToTarget()
    }


    private fun clearPendingResult() {
        this.pendingResult = null
    }

    companion object {
        private const val TAG = "FilePickerDelegate"
        private val REQUEST_CODE = (FilePickerPlugin::class.java.hashCode() + 43) and 0x0000ffff
        private val SAVE_FILE_CODE = (FilePickerPlugin::class.java.hashCode() + 83) and 0x0000ffff

        private fun finishWithAlreadyActiveError(result: MethodChannel.Result) {
            result.error("already_active", "File picker is already active", null)
        }
    }
}
