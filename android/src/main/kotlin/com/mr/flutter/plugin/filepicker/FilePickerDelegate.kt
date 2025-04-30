package com.mr.flutter.plugin.filepicker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.mr.flutter.plugin.filepicker.FileUtils.processFiles
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.IOException

class FilePickerDelegate(
    val activity: Activity,
    var pendingResult: MethodChannel.Result? = null
) : ActivityResultListener {

    companion object {
        const val TAG = "FilePickerDelegate"
        val REQUEST_CODE = (FilePickerPlugin::class.java.hashCode() + 43) and 0x0000ffff
        val SAVE_FILE_CODE = (FilePickerPlugin::class.java.hashCode() + 83) and 0x0000ffff

        fun finishWithAlreadyActiveError(result: MethodChannel.Result) {
            result.error("already_active", "File picker is already active", null)
        }
    }

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
        return when (requestCode) {
            SAVE_FILE_CODE -> handleSaveFileResult(resultCode, data)
            REQUEST_CODE -> handleFilePickerResult(resultCode, data)
            else -> false.also {
                finishWithError(
                    "unknown_activity",
                    "Unknown activity error, please file an issue."
                )
            }
        }
    }

    private fun handleSaveFileResult(resultCode: Int, data: Intent?): Boolean {
        return when (resultCode) {
            Activity.RESULT_OK -> saveFile(data?.data)
            Activity.RESULT_CANCELED -> {
                finishWithSuccess(null)
                false
            }

            else -> false
        }
    }

    private fun saveFile(uri: Uri?): Boolean {
        uri ?: return false
        dispatchEventStatus(true)
        return try {
            val newUri = FileUtils.writeBytesData(context = activity, uri, bytes) ?: uri
            finishWithSuccess(newUri.path)
            true
        } catch (e: IOException) {
            Log.e(TAG, "Error while saving file", e)
            finishWithError("Error while saving file", e.message)
            false
        }
    }

    private fun handleFilePickerResult(resultCode: Int, data: Intent?): Boolean {
        return when (resultCode) {
            Activity.RESULT_OK -> {
                dispatchEventStatus(true)
                processFiles(activity, data, compressionQuality, loadDataToMemory, type.orEmpty())
                true
            }

            Activity.RESULT_CANCELED -> {
                finishWithSuccess(null)
                true
            }

            else -> false
        }
    }

    fun setPendingMethodCallResult(result: MethodChannel.Result): Boolean {
        return if (pendingResult == null) {
            pendingResult = result
            true
        } else {
            false
        }
    }

    fun finishWithSuccess(data: Any?) {
        dispatchEventStatus(false)
        pendingResult?.let {
            it.success(data?.takeIf { it is String }
                ?: (data as? ArrayList<*>)?.mapNotNull { (it as? FileInfo)?.toMap() })
            clearPendingResult()
        }
    }

    fun finishWithError(errorCode: String, errorMessage: String?) {
        dispatchEventStatus(false)
        pendingResult?.error(errorCode, errorMessage, null)
        clearPendingResult()
    }

    private fun dispatchEventStatus(status: Boolean) {
        if (eventSink != null && type != "dir") {
            Handler(Looper.getMainLooper()).post { eventSink?.success(status) }
        }
    }

    private fun clearPendingResult() {
        pendingResult = null
    }
}