package com.mr.flutter.plugin.filepicker

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.mr.flutter.plugin.filepicker.FileUtils.clearCache
import com.mr.flutter.plugin.filepicker.FileUtils.getMimeTypes
import com.mr.flutter.plugin.filepicker.FileUtils.saveFile
import com.mr.flutter.plugin.filepicker.FileUtils.startFileExplorer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.util.HashMap

/**
 * FilePickerPlugin
 */
class FilePickerPlugin : MethodCallHandler, FlutterPlugin,
    ActivityAware {
    private inner class LifeCycleObserver
        (private val thisActivity: Activity) : Application.ActivityLifecycleCallbacks,
        DefaultLifecycleObserver {
        override fun onCreate(owner: LifecycleOwner) {
        }

        override fun onStart(owner: LifecycleOwner) {
        }

        override fun onResume(owner: LifecycleOwner) {
        }

        override fun onPause(owner: LifecycleOwner) {
        }

        override fun onStop(owner: LifecycleOwner) {
            this.onActivityStopped(this.thisActivity)
        }

        override fun onDestroy(owner: LifecycleOwner) {
            this.onActivityDestroyed(this.thisActivity)
        }

        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        }

        override fun onActivityStarted(activity: Activity) {
        }

        override fun onActivityResumed(activity: Activity) {
        }

        override fun onActivityPaused(activity: Activity) {
        }

        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        }

        override fun onActivityDestroyed(activity: Activity) {
            if (this.thisActivity === activity && activity.applicationContext != null) {
                (activity.applicationContext as Application).unregisterActivityLifecycleCallbacks(
                    this
                ) // Use getApplicationContext() to avoid casting failures
            }
        }

        override fun onActivityStopped(activity: Activity) {
        }
    }

    private var activityBinding: ActivityPluginBinding? = null
    private var delegate: FilePickerDelegate? = null
    private var application: Application? = null
    private var pluginBinding: FlutterPluginBinding? = null

    // This is null when not using v2 embedding;
    private var lifecycle: Lifecycle? = null
    private var observer: LifeCycleObserver? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null
    override fun onMethodCall(call: MethodCall, rawResult: MethodChannel.Result) {
        if (this.activity == null) {
            rawResult.error("no_activity", "file picker plugin requires a foreground activity", null)
            return
        }

        val result: MethodChannel.Result = MethodResultWrapper(rawResult)
        val arguments = call.arguments as? HashMap<*, *>
        val method = call.method

        when (method) {
            "clear" -> {
                result.success(clearCache(activity!!.applicationContext))
            }
            "save" -> {
                val fileName = arguments?.get("fileName") as String?
                val type = resolveType(arguments?.get("fileType") as String)
                val initialDirectory = arguments?.get("initialDirectory") as String?
                val allowedExtensions = getMimeTypes(arguments?.get("allowedExtensions") as ArrayList<String>?)
                val bytes = arguments?.get("bytes") as ByteArray?
                delegate!!.saveFile(fileName, type, initialDirectory, allowedExtensions, bytes, result)
            }
            "custom" -> {
                val allowedExtensions = getMimeTypes(arguments?.get("allowedExtensions") as ArrayList<String>?)
                if (allowedExtensions.isNullOrEmpty()) {
                    result.error(TAG, "Unsupported filter. Ensure using extension without dot (e.g., jpg, not .jpg).", null)
                } else {
                    delegate!!.startFileExplorer(
                        resolveType(call.method),
                        arguments?.get("allowMultipleSelection") as Boolean,
                        arguments?.get("withData") as Boolean,
                        allowedExtensions,
                        arguments?.get("compressionQuality") as Int,
                        result
                    )
                }
            }
            else -> {
                val fileType = resolveType(method)
                if (fileType == null) {
                    result.notImplemented()
                } else if (fileType != "dir") {
                    delegate!!.startFileExplorer(
                        fileType,
                        arguments?.get("allowMultipleSelection") as Boolean,
                        arguments?.get("withData") as Boolean,
                        getMimeTypes(arguments?.get("allowedExtensions") as ArrayList<String>?),
                        arguments?.get("compressionQuality") as Int,
                        result
                    )
                }
            }
        }
    }

    // MethodChannel.Result wrapper that responds on the platform thread.
    private class MethodResultWrapper(private val methodResult: MethodChannel.Result) :
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


    private fun setup(
        messenger: BinaryMessenger,
        application: Application,
        activity: Activity,
        activityBinding: ActivityPluginBinding
    ) {
        this.activity = activity
        this.application = application
        this.delegate = FilePickerDelegate(activity)
        this.channel = MethodChannel(messenger, CHANNEL)
        channel!!.setMethodCallHandler(this)
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object :
            EventChannel.StreamHandler {
            override fun onListen(arguments: Any, events: EventSink) {
                delegate!!.setEventHandler(events)
            }

            override fun onCancel(arguments: Any) {
                delegate!!.setEventHandler(null)
            }
        })
        this.observer = LifeCycleObserver(activity)

        // V2 embedding setup for activity listeners.
        activityBinding.addActivityResultListener(delegate!!)
        this.lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(activityBinding)
        lifecycle!!.addObserver(observer!!)
    }

    private fun tearDown() {
        activityBinding!!.removeActivityResultListener(delegate!!)
        this.activityBinding = null
        if (this.observer != null) {
            lifecycle!!.removeObserver(observer!!)
            application!!.unregisterActivityLifecycleCallbacks(this.observer)
        }
        this.lifecycle = null
        delegate!!.setEventHandler(null)
        this.delegate = null
        channel!!.setMethodCallHandler(null)
        this.channel = null
        this.application = null
    }

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        this.pluginBinding = binding
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        this.pluginBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activityBinding = binding
        this.setup(
            pluginBinding!!.binaryMessenger,
            pluginBinding!!.applicationContext as Application,
            activityBinding!!.activity,
            activityBinding!!
        )
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        this.tearDown()
    }

    companion object {
        private const val TAG = "FilePicker"
        private const val CHANNEL = "miguelruivo.flutter.plugins.filepicker"
        private const val EVENT_CHANNEL = "miguelruivo.flutter.plugins.filepickerevent"

        private var fileType: String? = null
        private var isMultipleSelection = false
        private var withData = false
        private var compressionQuality = 0

        private fun resolveType(type: String): String? {
            return when (type) {
                "audio" -> "audio/*"
                "image" -> "image/*"
                "video" -> "video/*"
                "media" -> "image/*,video/*"
                "any", "custom" -> "*/*"
                "dir" -> "dir"
                else -> null
            }
        }
    }
}
