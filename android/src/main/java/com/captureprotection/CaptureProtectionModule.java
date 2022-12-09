package com.captureprotection;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

import android.view.WindowManager;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

@ReactModule(name = CaptureProtectionModule.NAME)
public class CaptureProtectionModule extends ReactContextBaseJavaModule {
  public static final String NAME = "CaptureProtection";
  private final ReactApplicationContext reactContext;
  private static boolean isSecureFlag = false;

  public CaptureProtectionModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void preventScreenshot(Promise promise) {
    runOnUiThread(new Runnable() {
      @Override
      public void run() {
        try {
          reactContext.getCurrentActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
          isSecureFlag = true;
          promise.resolve(true);
        } catch(Exception e) {
          promise.reject("preventScreenshot", e);
        }
      }
    });
  }

  @ReactMethod
  public void allowScreenshot(Promise promise) {
    runOnUiThread(new Runnable() {
      @Override
      public void run() {
        try {
          reactContext.getCurrentActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
          isSecureFlag = false;
          promise.resolve(true);
        } catch (Exception e) {
          promise.reject("allowScreenshot", e);
        }
      }
    });
  }

  @ReactMethod
  public void getPreventStatus(Promise promise) {
    WritableMap statusMap = Arguments.createMap();
    statusMap.putBoolean("screenshot", isSecureFlag); 
    statusMap.putBoolean("record", isSecureFlag); 
    promise.resolve(statusMap);
  }
}
