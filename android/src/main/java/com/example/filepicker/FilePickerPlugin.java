package com.example.filepicker;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FilePickerPlugin */
public class FilePickerPlugin implements MethodCallHandler {


  private static final int REQUEST_CODE = 43;
  private static Result result;
  private static Registrar instance;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "file_picker");
    channel.setMethodCallHandler(new FilePickerPlugin());
    instance = registrar;
    instance.addActivityResultListener(new PluginRegistry.ActivityResultListener()
    {
      @Override
      public boolean onActivityResult(int requestCode, int resultCode, Intent data)
      {
        if(requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {

          if(data != null) {
            Uri uri = data.getData();
            result.success(uri.getPath());
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



  private void startFileExplorer()
  {

    Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
    intent.setType("application/pdf");
    intent.addCategory(Intent.CATEGORY_OPENABLE);
    instance.activity().startActivityForResult(intent,REQUEST_CODE);

  }


}
