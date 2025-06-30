package com.mr.flutter.plugin.filepicker

import android.app.Activity
import android.app.Application
import android.os.Bundle
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.mr.flutter.plugin.filepicker.FileUtils.clearCache
import com.mr.flutter.plugin.filepicker.FileUtils.getFileExtension
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

/**
 * FilePickerPlugin
 */
class FilePickerPlugin : MethodCallHandler, FlutterPlugin,
    ActivityAware {

    companion object {
        private const val TAG = "FilePicker"
        private const val CHANNEL = "miguelruivo.flutter.plugins.filepicker"
        private const val EVENT_CHANNEL = "miguelruivo.flutter.plugins.filepickerevent"

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
            // Use getApplicationContext() to avoid casting failures
            if (this.thisActivity === activity && activity.applicationContext != null) {
                (activity.applicationContext as Application).unregisterActivityLifecycleCallbacks(
                    this
                )
            }
        }

        override fun onActivityStopped(activity: Activity) {
        }
    }

    private var activityBinding: ActivityPluginBinding? = null
    private var delegate: FilePickerDelegate? = null
    private var application: Application? = null
    private var pluginBinding: FlutterPluginBinding? = null

    // TODO: Remove references to v1 embedding once the minimum Flutter version is >= 3.29
    // See: https://docs.flutter.dev/release/breaking-changes/v1-android-embedding
    // This will be null when not using the v2 embedding
    private var lifecycle: Lifecycle? = null
    private var observer: LifeCycleObserver? = null
    private var activity: Activity? = null
    private var channel: MethodChannel? = null

    override fun onMethodCall(call: MethodCall, rawResult: MethodChannel.Result) {
        if (this.activity == null) {
            rawResult.error(
                "no_activity",
                "file picker plugin requires a foreground activity",
                null
            )
            return
        }

        val result: MethodChannel.Result = MethodResultWrapper(rawResult)
        val arguments = call.arguments as? HashMap<*, *>
        val method = call.method

        when (method) {
            "clear" -> {
                result.success(activity?.applicationContext?.let { clearCache(it) })
            }

            "save" -> {
                val type = resolveType(arguments?.get("fileType") as String)
                val initialDirectory = arguments?.get("initialDirectory") as String?
                val bytes = arguments?.get("bytes") as ByteArray?
                val fileNameWithoutExtension = "${arguments?.get("fileName")}"
                val fileName =
                    if (fileNameWithoutExtension.isNotEmpty() && !fileNameWithoutExtension.contains(
                            "."
                        )
                    ) "$fileNameWithoutExtension.${getFileExtension(bytes)}" else fileNameWithoutExtension
                delegate?.saveFile(fileName, type, initialDirectory, bytes, result)
            }

            "custom" -> {
                val allowedExtensions =
                    getMimeTypes(arguments?.get("allowedExtensions") as ArrayList<String>?)
                if (allowedExtensions.isNullOrEmpty()) {
                    result.error(
                        TAG,
                        "Unsupported filter. Ensure using extension without dot (e.g., jpg, not .jpg).",
                        null
                    )
                } else {
                    delegate?.startFileExplorer(
                        resolveType(method),
                        arguments?.get("allowMultipleSelection") as Boolean?,
                        arguments?.get("withData") as Boolean?,
                        allowedExtensions,
                        arguments?.get("compressionQuality") as Int?,
                        result
                    )
                }
            }

            else -> {
                val fileType = resolveType(method)
                if (fileType == null) {
                    result.notImplemented()
                    return
                }

                delegate?.startFileExplorer(
                    fileType,
                    arguments?.get("allowMultipleSelection") as Boolean?,
                    arguments?.get("withData") as Boolean?,
                    getMimeTypes(arguments?.get("allowedExtensions") as ArrayList<String>?),
                    arguments?.get("compressionQuality") as Int?,
                    result
                )
            }
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
        channel?.setMethodCallHandler(this)
        delegate?.let { it ->
            EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object :
                EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink?) {
                    it.setEventHandler(events)
                }

                override fun onCancel(arguments: Any?) {
                    it.setEventHandler(null)
                }
            })
            this.observer = LifeCycleObserver(activity)

            // V2 embedding setup for activity listeners.
            activityBinding.addActivityResultListener(it)
            this.lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(activityBinding)
            observer?.let { it -> lifecycle?.addObserver(it) }
        }
    }

    private fun tearDown() {
        delegate?.let { it ->
            activityBinding?.removeActivityResultListener(it)
        }
        this.activityBinding = null
        observer?.let { it ->
            lifecycle?.removeObserver(it)
            application?.unregisterActivityLifecycleCallbacks(it)
        }
        this.lifecycle = null
        delegate?.setEventHandler(null)
        this.delegate = null
        channel?.setMethodCallHandler(null)
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
        pluginBinding?.let { it ->
            this.setup(
                it.binaryMessenger,
                it.applicationContext as Application,
                activityBinding!!.activity,
                activityBinding!!
            )
        }
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
}
