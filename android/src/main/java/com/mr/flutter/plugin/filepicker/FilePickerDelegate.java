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
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

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
    private boolean loadDataToMemory = false;
    private String type;
    private String[] allowedExtensions;
    private EventChannel.EventSink eventSink;
    private final FilePickerCache cache;

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

                },
                new FilePickerCache(activity)
        );
    }

    public void setEventHandler(final EventChannel.EventSink eventSink) {
        this.eventSink = eventSink;
    }

    @VisibleForTesting
    FilePickerDelegate(final Activity activity, final MethodChannel.Result result, final PermissionManager permissionManager, final FilePickerCache cache) {
        this.activity = activity;
        this.pendingResult = result;
        this.permissionManager = permissionManager;
        this.cache = cache;
    }


    @Override
    public boolean onActivityResult(final int requestCode, final int resultCode, final Intent data) {

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {

            if (eventSink != null) {
                eventSink.success(true);
            }
            if (pendingResult != null) {
                if(type == null) {
                    return false;
                }

                handleSuccessResult(data);
                return true;
            } else {
                type = cache.retrieveType();
                if (type != null && !type.equals("dir")) {
                    cache.saveResult(data, null, null);
                }
            }
        } else if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_CANCELED) {
            Log.i(TAG, "User cancelled the picker request");
            if (pendingResult != null) {
                finishWithSuccess(null);
            } else {
                cache.clear();
            }
            return true;
        } else if (requestCode == REQUEST_CODE) {
            finishWithError("unknown_activity", "Unknown activity error, please fill an issue.");
        }
        return false;
    }

    private void handleSuccessResult(final Intent data) {
        new Thread(new Runnable() {
            @Override
            public void run() {
                if (data != null) {
                    final ArrayList<FileInfo> files = new ArrayList<>();

                    if (data.getClipData() != null) {
                        final int count = data.getClipData().getItemCount();
                        int currentItem = 0;
                        while (currentItem < count) {
                            final Uri currentUri = data.getClipData().getItemAt(currentItem).getUri();
                            final FileInfo file = FileUtils.openFileStream(FilePickerDelegate.this.activity, currentUri, loadDataToMemory);

                            if (file != null) {
                                files.add(file);
                                Log.d(FilePickerDelegate.TAG, "[MultiFilePick] File #" + currentItem + " - URI: " + currentUri.getPath());
                            }
                            currentItem++;
                        }

                        finishWithSuccess(files);
                    } else if (data.getData() != null) {
                        Uri uri = data.getData();

                        if (type != null && type.equals("dir") && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            uri = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri));

                            Log.d(FilePickerDelegate.TAG, "[SingleFilePick] File URI:" + uri.toString());
                            final String dirPath = FileUtils.getFullPathFromTreeUri(uri, activity);

                            if (dirPath != null) {
                                finishWithSuccess(dirPath);
                            } else {
                                finishWithError("unknown_path", "Failed to retrieve directory path.");
                            }
                            return;
                        }

                        final FileInfo file = FileUtils.openFileStream(FilePickerDelegate.this.activity, uri, loadDataToMemory);

                        if (file != null) {
                            files.add(file);
                        }

                        if (!files.isEmpty()) {
                            Log.d(FilePickerDelegate.TAG, "File path:" + files.toString());
                            finishWithSuccess(files);
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

        // Clean up cache if a new file picker is launched.
        cache.clear();
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
            if (type.equals("image/*")) {
                intent = new Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
            } else {
                intent = new Intent(Intent.ACTION_GET_CONTENT);
                intent.addCategory(Intent.CATEGORY_OPENABLE);
            }
            final Uri uri = Uri.parse(Environment.getExternalStorageDirectory().getPath() + File.separator);
            Log.d(TAG, "Selected type " + type);
            intent.setDataAndType(uri, this.type);
            intent.setType(this.type);
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, this.isMultipleSelection);

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
    public void startFileExplorer(final String type, final boolean isMultipleSelection, final boolean withData, final String[] allowedExtensions, final MethodChannel.Result result) {

        if (!this.setPendingMethodCallAndResult(result)) {
            finishWithAlreadyActiveError(result);
            return;
        }

        this.type = type;
        this.isMultipleSelection = isMultipleSelection;
        this.loadDataToMemory = withData;
        this.allowedExtensions = allowedExtensions;

        if (!this.permissionManager.isPermissionGranted(Manifest.permission.READ_EXTERNAL_STORAGE)) {
            this.permissionManager.askForPermission(Manifest.permission.READ_EXTERNAL_STORAGE, REQUEST_CODE);
            return;
        }

        this.startFileExplorer();
    }

    void saveStateBeforeResult() {
        cache.saveLoadDataToMemory(loadDataToMemory);
        cache.saveType(type);
    }

    @SuppressWarnings("unchecked")
    void retrieveLostFiles(MethodChannel.Result result) {
        final Boolean loadDataToMemory = cache.retrieveLoadDataToMemory();
        Map<String, Object> cacheMap = cache.getCacheMap();
        Set<String> paths = (Set<String>) cacheMap.get(cache.MAP_KEY_PATHS);
        if (paths != null) {
            final ArrayList<FileInfo> files = new ArrayList<>();
            for (String path : paths) {
                Uri uri = Uri.parse(path);
                final FileInfo file = FileUtils.openFileStream(FilePickerDelegate.this.activity, uri, loadDataToMemory);

                if (file != null) {
                    files.add(file);
                }
            }
            if (files.isEmpty()) {
                result.success(null);
            } else {
                final ArrayList<HashMap<String, Object>> resultFiles = new ArrayList<>();
                for (FileInfo file : files) {
                    resultFiles.add(file.toMap());
                }
                final HashMap<String, Object> resultMap = new HashMap<>();
                resultMap.put("filePickerResult", resultFiles);
                result.success(resultMap);
            }
        } else if (cacheMap.isEmpty()){
            result.success(null);
        } else {
            result.success(cacheMap);
        }
        cache.clear();
    }

    @SuppressWarnings("unchecked")
    private void finishWithSuccess(Object data) {
        if (eventSink != null) {
            this.dispatchEventStatus(false);
        }

        // Temporary fix, remove this null-check after Flutter Engine 1.14 has landed on stable
        if (this.pendingResult != null) {
            cache.clear(); // as we are sending the result, don't need to keep it

            if (data != null && !(data instanceof String)) {
                final ArrayList<HashMap<String, Object>> files = new ArrayList<>();

                for (FileInfo file : (ArrayList<FileInfo>) data) {
                    files.add(file.toMap());
                }
                data = files;
            }

            this.pendingResult.success(data);
            this.clearPendingResult();
        }
    }

    private void finishWithError(final String errorCode, final String errorMessage) {
        if (this.pendingResult == null) {
            cache.saveResult(null, errorCode, errorMessage);
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
