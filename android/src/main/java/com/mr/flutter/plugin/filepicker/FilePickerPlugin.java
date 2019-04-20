package com.mr.flutter.plugin.filepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.util.Log;
import android.webkit.MimeTypeMap;


import java.io.File;
import java.util.ArrayList;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FilePickerPlugin */
public class FilePickerPlugin implements MethodCallHandler {

  private static final int REQUEST_CODE = (FilePickerPlugin.class.hashCode() + 43) & 0x0000ffff;
  private static final int PERM_CODE = (FilePickerPlugin.class.hashCode() + 50) & 0x0000ffff;
  private static final String TAG = "FilePicker";
  private static final String permission = Manifest.permission.WRITE_EXTERNAL_STORAGE;

  private static Result result;
  private static Registrar instance;
  private static String fileType;
  private static boolean isMultipleSelection = false;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {

    if (registrar.activity() == null) {
        // If a background flutter view tries to register the plugin, there will be no activity from the registrar,
        // we stop the registering process immediately because the ImagePicker requires an activity.
        return;
    }

    final MethodChannel channel = new MethodChannel(registrar.messenger(), "file_picker");
    channel.setMethodCallHandler(new FilePickerPlugin());

    instance = registrar;
    instance.addActivityResultListener(new PluginRegistry.ActivityResultListener() {
      @Override
      public boolean onActivityResult(int requestCode, int resultCode, Intent data) {

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {

          if(data.getClipData() != null) {
            int count = data.getClipData().getItemCount();
            int currentItem = 0;
            ArrayList<String> paths = new ArrayList<>();
            while(currentItem < count) {
              final Uri currentUri = data.getClipData().getItemAt(currentItem).getUri();
              String path = FileUtils.getPath(currentUri, instance.context());
              paths.add(path);
              Log.i(TAG, "[MultiFilePick] File #" + currentItem + " - URI: " +currentUri.getPath());
              currentItem++;
            }
            if(paths.size() > 1){
              result.success(paths);
            } else {
              result.success(paths.get(0));
            }
          } else if (data != null) {
            Uri uri = data.getData();
            Log.i(TAG, "[SingleFilePick] File URI:" +data.getData().toString());
            String fullPath = FileUtils.getPath(uri, instance.context());

            if(fullPath == null) {
             fullPath =  FileUtils.getUriFromRemote(instance.activeContext(), uri, result);
            }

            if(fullPath != null) {
              Log.i(TAG, "Absolute file path:" + fullPath);
              result.success(fullPath);
            } else {
              result.error(TAG, "Failed to retrieve path." ,null);
            }
          }
          return true;
        } else if(requestCode == REQUEST_CODE && resultCode == Activity.RESULT_CANCELED) {
            result.success(null);
            return true;
        } else if (requestCode == REQUEST_CODE) {
          result.error(TAG, "Unknown activity error, please fill an issue." ,null);
        }
        return false;
      }
    });

    instance.addRequestPermissionsResultListener(new PluginRegistry.RequestPermissionsResultListener() {
      @Override
      public boolean onRequestPermissionsResult(int requestCode, String[] strings, int[] grantResults) {
        if (requestCode == PERM_CODE && grantResults.length > 0
                && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
          startFileExplorer(fileType);
          return true;
        }
        return false;
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    this.result = result;
    fileType = resolveType(call.method);
    isMultipleSelection = (boolean)call.arguments;

    if(fileType == null) {
      result.notImplemented();
    } else if(fileType.equals("unsupported")) {
      result.error(TAG, "Unsupported filter. Make sure that you are only using the extension without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension.  If the problem persists, you may want to consider using FileType.ALL instead." ,null);
    } else {
      startFileExplorer(fileType);
    }

  }

  private static boolean checkPermission() {
    Activity activity = instance.activity();
    Log.i(TAG, "Checking permission: " + permission);
    return PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(activity, permission);
  }

  private static void requestPermission() {
    Activity activity = instance.activity();
    Log.i(TAG, "Requesting permission: " + permission);
    String[] perm = { permission };
    ActivityCompat.requestPermissions(activity, perm, PERM_CODE);
  }

  private String resolveType(String type) {

    final boolean isCustom = type.contains("__CUSTOM_");

    if(isCustom) {
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




  private static void startFileExplorer(String type) {
    Intent intent;

    if (checkPermission()) {
      if(Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
        intent = new Intent(Intent.ACTION_PICK);
      } else {
        intent = new Intent(Intent.ACTION_GET_CONTENT);
      }

      Uri uri = Uri.parse(Environment.getExternalStorageDirectory().getPath() + File.separator);
      intent.setDataAndType(uri, type);
      intent.setType(type);
      intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, isMultipleSelection);
      intent.addCategory(Intent.CATEGORY_OPENABLE);

      instance.activity().startActivityForResult(intent, REQUEST_CODE);
    } else {
      requestPermission();
    }
  }

}
