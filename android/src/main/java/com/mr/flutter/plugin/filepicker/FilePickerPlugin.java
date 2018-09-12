package com.mr.flutter.plugin.filepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import java.io.BufferedOutputStream;
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

  private static final int REQUEST_CODE = 43;
  private static final String TAG = "FilePicker";

  private static final String permission = Manifest.permission.WRITE_EXTERNAL_STORAGE;
  private static Result result;
  private static Registrar instance;

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
            String fullPath = FilePath.getPath(uri, instance.context());
            String cloudFile = null;

            if(fullPath == null)
            {
              FileOutputStream fos = null;
              cloudFile = instance.activeContext().getCacheDir().getAbsolutePath() + "/Document";

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

              Log.i(TAG, "Loaded file from cloud created on:" + cloudFile);
              fullPath = cloudFile;
            }

            Log.i(TAG, "Absolute file path:" + fullPath);
            result.success(fullPath);
          }

        }
        return false;
      }
    });
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("pickPDF")) {
      this.result = result;
      startFileExplorer();
    } else {
      result.notImplemented();
    }
  }

  private boolean checkPermission() {
    Activity activity = instance.activity();
    Log.i(TAG, "Checking permission: " + permission);
    return PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(activity, permission);
  }

  private void requestPermission() {
    Activity activity = instance.activity();
    Log.i(TAG, "Requesting permission: " + permission);
    String[] perm = { permission };
    ActivityCompat.requestPermissions(activity, perm, 0);
  }

  private void startFileExplorer() {
    Intent intent;

    if (checkPermission()) {
      if(Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT){
        intent = new Intent(Intent.ACTION_PICK);
      }else{
        intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
      }

      intent.setType("application/pdf");
      intent.addCategory(Intent.CATEGORY_OPENABLE);
      instance.activity().startActivityForResult(intent, REQUEST_CODE);
    } else {
      requestPermission();
      startFileExplorer();
    }
  }

}
