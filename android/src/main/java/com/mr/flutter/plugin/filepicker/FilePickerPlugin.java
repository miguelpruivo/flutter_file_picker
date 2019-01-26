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

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;


import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FilePickerPlugin */
public class FilePickerPlugin implements MethodCallHandler {

  private static final int REQUEST_CODE = FilePickerPlugin.class.hashCode() + 43;
  private static final int PERM_CODE = FilePickerPlugin.class.hashCode() + 50;
  private static final String TAG = "FilePicker";
  private static final String permission = Manifest.permission.WRITE_EXTERNAL_STORAGE;

  private static Result result;
  private static Registrar instance;
  private static String fileType;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "file_picker");
    channel.setMethodCallHandler(new FilePickerPlugin());

    instance = registrar;
    instance.addActivityResultListener(new PluginRegistry.ActivityResultListener() {
      @Override
      public boolean onActivityResult(int requestCode, int resultCode, Intent data) {

        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {

          if (data != null) {
            Uri uri = data.getData();
            Log.i(TAG, "URI:" +data.getData().toString());
            String fullPath = FileUtils.getPath(uri, instance.context());
            String cloudFile = null;

            if(fullPath == null)
            {
              FileOutputStream fos = null;
              cloudFile = instance.activeContext().getCacheDir().getAbsolutePath() + "/" + FileUtils.getFileName(uri, instance.activeContext());

              try {
                fos = new FileOutputStream(cloudFile);
                try{
                  BufferedOutputStream out = new BufferedOutputStream(fos);
                  InputStream in = instance.activeContext().getContentResolver().openInputStream(uri);

                  byte[] buffer = new byte[8192];
                  int len = 0;

                  while ((len = in.read(buffer)) >= 0){
                    out.write(buffer, 0, len);
                  }

                  out.flush();
                } finally {
                  fos.getFD().sync();
                }

              } catch (Exception e) {
                e.printStackTrace();
              }

              Log.i(TAG, "Cloud file loaded and cached on:" + cloudFile);
              fullPath = cloudFile;
            }

            Log.i(TAG, "Absolute file path:" + fullPath);
            result.success(fullPath);
          }

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

    if(fileType == null){
      result.notImplemented();
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
      Log.i(TAG, "Custom file type: " + mime);
      return mime;
    }

    switch (type) {
      case "PDF":
        return "application/pdf";
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
      intent.addCategory(Intent.CATEGORY_OPENABLE);

      Log.d(TAG, "Intent: " + intent.toString());

      instance.activity().startActivityForResult(intent, REQUEST_CODE);
    } else {
      requestPermission();
    }
  }

}
