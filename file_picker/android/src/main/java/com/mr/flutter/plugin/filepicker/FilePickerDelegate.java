package com.mr.flutter.plugin.filepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.provider.DocumentsContract;
import android.util.Log;

import androidx.annotation.VisibleForTesting;
import androidx.core.app.ActivityCompat;

import java.io.File;
import java.util.ArrayList;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class FilePickerDelegate implements PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {

    private static final String TAG = "FilePickerDelegate";
    private static final int REQUEST_CODE = (FilePickerPlugin.class.hashCode() + 43) & 0x0000ffff;

    private final Activity activity;
    private final PermissionManager permissionManager;
    private MethodChannel.Result pendingResult;
    private boolean isMultipleSelection = false;
    private String type;
    private String[] allowedExtensions;
    private EventChannel.EventSink eventSink;

    public FilePickerDelegate(final Activity activity) {
        this(
                activity,
                null,
                new PermissionManager() {
                    @Override
                    public boolean isPermissionGranted(final String permissionName) {
                        return ActivityCompat.checkSelfPermission(activity, permissionName)
                                == PackageManager.PERMISSION_GRANTED;
                    }

                    @Override
                    public void askForPermission(final String permissionName, final int requestCode) {
                        ActivityCompat.requestPermissions(activity, new String[]{permissionName}, requestCode);
                    }

                }
        );
    }

    public void setEventHandler(final EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @VisibleForTesting
    FilePickerDelegate(final Activity activity, final MethodChannel.Result result, final PermissionManager permissionManager) {
        this.activity = activity;
        this.pendingResult = result;
        this.permissionManager = permissionManager;
    }


    @Override
    public boolean onActivityResult(final int requestCode, final int resultCode, final Intent data) {

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {

            if (eventSink != null) {
                eventSink.success(true);
            }

            new Thread(new Runnable() {
                @Override
                public void run() {
                    if (data != null) {
                        if (data.getClipData() != null) {
                            final int count = data.getClipData().getItemCount();
                            int currentItem = 0;
                            final ArrayList<String> paths = new ArrayList<>();
                            while (currentItem < count) {
                                final Uri currentUri = data.getClipData().getItemAt(currentItem).getUri();
                                String path;
                                if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    path = FileUtils.getUriFromRemote(FilePickerDelegate.this.activity, currentUri);
                                } else {
                                    path = FileUtils.getPath(currentUri, FilePickerDelegate.this.activity);
                                    if (path == null) {
                                        path = FileUtils.getUriFromRemote(FilePickerDelegate.this.activity, currentUri);
                                    }
                                }
                                paths.add(path);
                                Log.i(FilePickerDelegate.TAG, "[MultiFilePick] File #" + currentItem + " - URI: " + currentUri.getPath());
                                currentItem++;
                            }
                            if (paths.size() > 1) {
                                finishWithSuccess(paths);
                            } else {
                                finishWithSuccess(paths.get(0));
                            }
                        } else if (data.getData() != null) {
                            Uri uri = data.getData();
                            String fullPath;
                            if (type.equals("dir") && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                uri = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));
                            }

                            Log.i(FilePickerDelegate.TAG, "[SingleFilePick] File URI:" + uri.toString());

                            if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                fullPath = type.equals("dir") ? FileUtils.getFullPathFromTreeUri(uri, activity) : FileUtils.getUriFromRemote(FilePickerDelegate.this.activity, uri);
                            } else {
                                fullPath = FileUtils.getPath(uri, FilePickerDelegate.this.activity);
                                if (fullPath == null) {
                                    fullPath = type.equals("dir") ? FileUtils.getFullPathFromTreeUri(uri, activity) : FileUtils.getUriFromRemote(FilePickerDelegate.this.activity, uri);
                                }
                            }

                            if (fullPath != null) {
                                Log.i(FilePickerDelegate.TAG, "Absolute file path:" + fullPath);
                                finishWithSuccess(fullPath);
                            } else {
                                finishWithError("unknown_path", "Failed to retrieve path.");
                            }

                        } else {
                            finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
                        }
                    } else {
                        finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
                    }
                }
            }).start();

            return true;

        } else if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_CANCELED) {
            Log.i(TAG, "User cancelled the picker request");
            finishWithSuccess(null);
            return true;
        } else if (requestCode == REQUEST_CODE) {
            finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        }
        return false;
    }

    @Override
    public boolean onRequestPermissionsResult(final int requestCode, final String[] permissions, final int[] grantResults) {

        if (REQUEST_CODE != requestCode) {
            return false;
        }

        final boolean permissionGranted =
                grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;

        if (permissionGranted) {
            this.startFileExplorer();
        } else {
            finishWithError("read_external_storage_denied", "User did not allowed reading external storage");
        }

        return true;
    }

    private boolean setPendingMethodCallAndResult(final MethodChannel.Result result) {
        if (this.pendingResult != null) {
            return false;
        }
        this.pendingResult = result;
        return true;
    }

    private static void finishWithAlreadyActiveError(final MethodChannel.Result result) {
        result.error("already_active", "File picker is already active", null);
    }

    @SuppressWarnings("deprecation")
    private void startFileExplorer() {
        final Intent intent;

        // Temporary fix, remove this null-check after Flutter Engine 1.14 has landed on stable
        if (type == null) {
            return;
        }

        if (type.equals("dir")) {
            intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        } else {
            intent = new Intent(Intent.ACTION_GET_CONTENT);
            final Uri uri = Uri.parse(Environment.getExternalStorageDirectory().getPath() + File.separator);
            Log.d(TAG, "Selected type " + type);
            intent.setDataAndType(uri, this.type);
            intent.setType(this.type);
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, this.isMultipleSelection);
            intent.addCategory(Intent.CATEGORY_OPENABLE);

            if (type.contains(",")) {
                allowedExtensions = type.split(",");
            }

            if (allowedExtensions != null) {
                intent.putExtra(Intent.EXTRA_MIME_TYPES, allowedExtensions);
            }
        }

        if (intent.resolveActivity(this.activity.getPackageManager()) != null) {
            this.activity.startActivityForResult(intent, REQUEST_CODE);
        } else {
            Log.e(TAG, "Can't find a valid activity to handle the request. Make sure you've a file explorer installed.");
            finishWithError("invalid_format_type", "Can't handle the provided file type.");
        }
    }

    @SuppressWarnings("deprecation")
    public void startFileExplorer(final String type, final boolean isMultipleSelection, final String[] allowedExtensions, final MethodChannel.Result result) {

        if (!this.setPendingMethodCallAndResult(result)) {
            finishWithAlreadyActiveError(result);
            return;
        }

        this.type = type;
        this.isMultipleSelection = isMultipleSelection;
        this.allowedExtensions = allowedExtensions;

        if (!this.permissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) {
            this.permissionManager.askForPermission(Manifest.permission.READ_EXTERNAL_STORAGE, REQUEST_CODE);
            return;
        }

        this.startFileExplorer();
    }

    private void finishWithSuccess(final Object data) {
        if (eventSink != null) {
            this.dispatchEventStatus(false);
        }

        // Temporary fix, remove this null-check after Flutter Engine 1.14 has landed on stable
        if (this.pendingResult != null) {
            this.pendingResult.success(data);
            this.clearPendingResult();
        }
    }

    private void finishWithError(final String errorCode, final String errorMessage) {
        if (this.pendingResult == null) {
            return;
        }

        if (eventSink != null) {
            this.dispatchEventStatus(false);
        }
        this.pendingResult.error(errorCode, errorMessage, null);
        this.clearPendingResult();
    }

    private void dispatchEventStatus(final boolean status) {
        new Handler(Looper.getMainLooper()) {
            @Override
            public void handleMessage(final Message message) {
                eventSink.success(status);
            }
        }.obtainMessage().sendToTarget();
    }


    private void clearPendingResult() {
        this.pendingResult = null;
    }

    interface PermissionManager {
        boolean isPermissionGranted(String permissionName);

        void askForPermission(String permissionName, int requestCode);
    }

}
