package com.mr.flutter.plugin.filepicker;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FilePickerPlugin
 */
public class FilePickerPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin, ActivityAware {

    private static final String TAG = "FilePicker";
    private static final String CHANNEL = "miguelruivo.flutter.plugins.file_picker";

    private class LifeCycleObserver
            implements Application.ActivityLifecycleCallbacks, DefaultLifecycleObserver {
        private final Activity thisActivity;

        LifeCycleObserver(final Activity activity) {
            this.thisActivity = activity;
        }

        @Override
        public void onCreate(@NonNull final LifecycleOwner owner) {
        }

        @Override
        public void onStart(@NonNull final LifecycleOwner owner) {
        }

        @Override
        public void onResume(@NonNull final LifecycleOwner owner) {
        }

        @Override
        public void onPause(@NonNull final LifecycleOwner owner) {
        }

        @Override
        public void onStop(@NonNull final LifecycleOwner owner) {
            this.onActivityStopped(this.thisActivity);
        }

        @Override
        public void onDestroy(@NonNull final LifecycleOwner owner) {
            this.onActivityDestroyed(this.thisActivity);
        }

        @Override
        public void onActivityCreated(final Activity activity, final Bundle savedInstanceState) {
        }

        @Override
        public void onActivityStarted(final Activity activity) {
        }

        @Override
        public void onActivityResumed(final Activity activity) {
        }

        @Override
        public void onActivityPaused(final Activity activity) {
        }

        @Override
        public void onActivitySaveInstanceState(final Activity activity, final Bundle outState) {
        }

        @Override
        public void onActivityDestroyed(final Activity activity) {
            if (this.thisActivity == activity && activity.getApplicationContext() != null) {
                ((Application) activity.getApplicationContext()).unregisterActivityLifecycleCallbacks(this); // Use getApplicationContext() to avoid casting failures
            }
        }

        @Override
        public void onActivityStopped(final Activity activity) {
        }
    }

    private ActivityPluginBinding activityBinding;
    private FilePickerDelegate delegate;
    private Application application;
    private FlutterPluginBinding pluginBinding;

    // This is null when not using v2 embedding;
    private Lifecycle lifecycle;
    private LifeCycleObserver observer;
    private Activity activity;
    private MethodChannel channel;
    private static String fileType;
    private static boolean isMultipleSelection = false;

    /**
     * Plugin registration.
     */
    public static void registerWith(final Registrar registrar) {

        if (registrar.activity() == null) {
            // If a background flutter view tries to register the plugin, there will be no activity from the registrar,
            // we stop the registering process immediately because the ImagePicker requires an activity.
            return;
        }

        final Activity activity = registrar.activity();
        Application application = null;
        if (registrar.context() != null) {
            application = (Application) (registrar.context().getApplicationContext());
        }

        final FilePickerPlugin plugin = new FilePickerPlugin();
        plugin.setup(registrar.messenger(), application, activity, registrar, null);

    }


    @Override
    public void onMethodCall(final MethodCall call, final MethodChannel.Result rawResult) {

        if (this.activity == null) {
            rawResult.error("no_activity", "file picker plugin requires a foreground activity", null);
            return;
        }

        final MethodChannel.Result result = new MethodResultWrapper(rawResult);
        fileType = FilePickerPlugin.resolveType(call.method);
        isMultipleSelection = (boolean) call.arguments;

        if (fileType == null) {
            result.notImplemented();
        } else if (fileType.equals("unsupported")) {
            result.error(TAG, "Unsupported filter. Make sure that you are only using the extension without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension.  If the problem persists, you may want to consider using FileType.ALL instead.", null);
        } else {
            this.delegate.startFileExplorer(fileType, isMultipleSelection, result);
        }

    }

    private static String resolveType(final String type) {

        final boolean isCustom = type.contains("__CUSTOM_");

        if (isCustom) {
            final String extension = type.split("__CUSTOM_")[1].toLowerCase();
            String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
            mime = mime == null ? "unsupported" : mime;
            Log.i(TAG, "Custom file type: " + mime);
            return mime;
        }

        switch (type) {
            case "AUDIO":
                return "audio/*";
            case "IMAGE":
                return "image/*";
            case "VIDEO":
                return "video/*";
            case "ANY":
                return "*/*";
            default:
                return null;
        }
    }


    // MethodChannel.Result wrapper that responds on the platform thread.
    private static class MethodResultWrapper implements MethodChannel.Result {
        private final MethodChannel.Result methodResult;
        private final Handler handler;

        MethodResultWrapper(final MethodChannel.Result result) {
            this.methodResult = result;
            this.handler = new Handler(Looper.getMainLooper());
        }

        @Override
        public void success(final Object result) {
            this.handler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            MethodResultWrapper.this.methodResult.success(result);
                        }
                    });
        }

        @Override
        public void error(
                final String errorCode, final String errorMessage, final Object errorDetails) {
            this.handler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            MethodResultWrapper.this.methodResult.error(errorCode, errorMessage, errorDetails);
                        }
                    });
        }

        @Override
        public void notImplemented() {
            this.handler.post(
                    new Runnable() {
                        @Override
                        public void run() {
                            MethodResultWrapper.this.methodResult.notImplemented();
                        }
                    });
        }
    }


    private void setup(
            final BinaryMessenger messenger,
            final Application application,
            final Activity activity,
            final PluginRegistry.Registrar registrar,
            final ActivityPluginBinding activityBinding) {

        this.activity = activity;
        this.application = application;
        this.delegate = new FilePickerDelegate(activity);
        this.channel = new MethodChannel(messenger, CHANNEL);
        this.channel.setMethodCallHandler(this);
        this.observer = new LifeCycleObserver(activity);
        if (registrar != null) {
            // V1 embedding setup for activity listeners.
            application.registerActivityLifecycleCallbacks(this.observer);
            registrar.addActivityResultListener(this.delegate);
            registrar.addRequestPermissionsResultListener(this.delegate);
        } else {
            // V2 embedding setup for activity listeners.
            activityBinding.addActivityResultListener(this.delegate);
            activityBinding.addRequestPermissionsResultListener(this.delegate);
            this.lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(activityBinding);
            this.lifecycle.addObserver(this.observer);
        }
    }

    private void tearDown() {
        this.activityBinding.removeActivityResultListener(this.delegate);
        this.activityBinding.removeRequestPermissionsResultListener(this.delegate);
        this.activityBinding = null;
        this.lifecycle.removeObserver(this.observer);
        this.lifecycle = null;
        this.delegate = null;
        this.channel.setMethodCallHandler(null);
        this.channel = null;
        this.application.unregisterActivityLifecycleCallbacks(this.observer);
        this.application = null;
    }

    @Override
    public void onAttachedToEngine(final FlutterPluginBinding binding) {
        this.pluginBinding = binding;
    }

    @Override
    public void onDetachedFromEngine(final FlutterPluginBinding binding) {
        this.pluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(final ActivityPluginBinding binding) {
        this.activityBinding = binding;
        this.setup(
                this.pluginBinding.getBinaryMessenger(),
                (Application) this.pluginBinding.getApplicationContext(),
                this.activityBinding.getActivity(),
                null,
                this.activityBinding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        this.onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(final ActivityPluginBinding binding) {
        this.onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        this.tearDown();
    }
}
