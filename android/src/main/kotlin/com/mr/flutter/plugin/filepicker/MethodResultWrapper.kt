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
            methodResult.success(
                result
            )
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