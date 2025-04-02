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
import com.mr.flutter.plugin.filepicker.FileUtils.processFiles
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class FilePickerDelegate @VisibleForTesting internal constructor(
    val activity: Activity,
    var pendingResult: MethodChannel.Result? = null
) :
    ActivityResultListener {
    var isMultipleSelection = false
    var loadDataToMemory = false
    var type: String? = null
    var compressionQuality = 0
    var allowedExtensions: ArrayList<String?>? = null
    var eventSink: EventSink? = null

    var bytes: ByteArray? = null

    fun setEventHandler(eventSink: EventSink?) {
        this.eventSink = eventSink
    }


    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // Save file
        if (requestCode == SAVE_FILE_CODE) {
            when (resultCode) {
                Activity.RESULT_OK -> {
                    val uri = data?.data ?: return false
                    dispatchEventStatus(true)

                    val fileName = getFileName(uri, activity)
                    val path = "${Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath}/$fileName"

                    try {
                        activity.contentResolver.openOutputStream(uri)?.use { outputStream ->
                            outputStream.write(bytes)
                            outputStream.flush()
                        }
                        finishWithSuccess(path)
                        return true
                    } catch (e: IOException) {
                        Log.i(TAG, "Error while saving file", e)
                        finishWithError("Error while saving file", e.message)
                    }
                }
                Activity.RESULT_CANCELED -> {
                    Log.i(TAG, "User cancelled the save request")
                    finishWithSuccess(null)
                }
            }
            return false
        }

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            this.dispatchEventStatus(true)
            processFiles(activity, data, compressionQuality, loadDataToMemory, type!!)
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
    fun setPendingMethodCallAndResult(result: MethodChannel.Result): Boolean {
        if (this.pendingResult != null) {
            return false
        }
        this.pendingResult = result
        return true
    }
    fun finishWithSuccess(data: Any?) {
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

    fun finishWithError(errorCode: String, errorMessage: String?) {
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
        const val TAG = "FilePickerDelegate"
        val REQUEST_CODE = (FilePickerPlugin::class.java.hashCode() + 43) and 0x0000ffff
        val SAVE_FILE_CODE = (FilePickerPlugin::class.java.hashCode() + 83) and 0x0000ffff

        fun finishWithAlreadyActiveError(result: MethodChannel.Result) {
            result.error("already_active", "File picker is already active", null)
        }
    }
}
