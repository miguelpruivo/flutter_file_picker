package com.mr.flutter.plugin.filepicker

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

// MethodChannel.Result wrapper that responds on the platform thread.
class MethodResultWrapper(private val methodResult: MethodChannel.Result) :
    MethodChannel.Result {
    private val handler =
        Handler(Looper.getMainLooper())

    override fun success(result: Any?) {
        handler.post {
            try {
                methodResult.success(
                    result
                )
            } catch (oom: OutOfMemoryError) {
                methodResult.error(
                    "out_of_memory",
                    "Selected files are too large to return in memory. Disable withData or use withReadStream.",
                    null
                )
            }
        }
    }

    override fun error(
        errorCode: String, errorMessage: String?, errorDetails: Any?
    ) {
        handler.post {
            methodResult.error(
                errorCode,
                errorMessage,
                errorDetails
            )
        }
    }

    override fun notImplemented() {
        handler.post { methodResult.notImplemented() }
    }
}