package com.mr.filepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;

import in.gauriinfotech.commons.Commons;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FilePickerPlugin */
public class FilePickerPlugin implements MethodCallHandler {

  private static final int REQUEST_CODE = 43;
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
            String fullPath = Commons.getPath(uri, instance.context());
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

  private String resolveFileType(String type) {
    switch (type) {
    case "PDF":
      break;

    case "IMAGES":
      break;
    }
  }

  private boolean checkPermission() {
    Activity activity = instance.activity();
    Log.i("SimplePermission", "Checking permission : " + permission);
    return PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(activity, permission);
  }

  private void requestPermission() {
    Activity activity = instance.activity();
    Log.i("File_Picker", "Requesting permission : " + permission);
    String[] perm = { permission };
    ActivityCompat.requestPermissions(activity, perm, 0);
  }

  private void startFileExplorer() {

    if (checkPermission()) {
      Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
      intent.setType("application/pdf");
      intent.addCategory(Intent.CATEGORY_OPENABLE);
      instance.activity().startActivityForResult(intent, REQUEST_CODE);
    } else {
      requestPermission();
    }
  }

}
