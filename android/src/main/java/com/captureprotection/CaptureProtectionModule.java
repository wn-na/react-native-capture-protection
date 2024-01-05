package com.captureprotection;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.ContentObserver;
import android.database.Cursor;
import android.hardware.display.DisplayManager;
import android.Manifest;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.provider.MediaStore;
import android.util.Log;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.util.ArrayList;
import java.util.concurrent.Executor;
import java.util.List;

@ReactModule(name = CaptureProtectionModule.NAME)
public class CaptureProtectionModule extends ReactContextBaseJavaModule {
  public static final String NAME = "CaptureProtection";
  private final ReactApplicationContext reactContext;
  private final DisplayManager displayManager;
  private List<Integer> screens;

  private ContentObserver contentObserver = null;

  Handler mainHandler;

  public CaptureProtectionModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    screens = new ArrayList<>();
    displayManager = (DisplayManager) reactContext.getSystemService(Context.DISPLAY_SERVICE);

    mainHandler = new Handler(reactContext.getMainLooper(), new Handler.Callback() {
      @Override
      public boolean handleMessage(@NonNull Message msg) {
        return false;
      }
    });
    displayManager.registerDisplayListener(new DisplayManager.DisplayListener() {
      @Override
      public void onDisplayAdded(int displayId) {
        runOnUiThread(() -> {
          if (displayManager.getDisplay(displayId) == null) {
            screens.add(displayId);
          }
          try {
            boolean flags = isSecureFlag();
            sendEvent(CaptureProtectionConstant.LISTENER_EVENT_NAME, flags, flags,
                screens.isEmpty()
                    ? CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal()
                    : CaptureProtectionConstant.CaptureProtectionModuleStatus.RECORD_DETECTED_START.ordinal());

            Log.d(NAME, "=> display add event " + displayId);
          } catch (Exception e) {
            Log.e(NAME, "display add event Error with displayId: " + displayId + ", error: " + e.getMessage());
          }
        });

      }

      @Override
      public void onDisplayRemoved(int displayId) {
        runOnUiThread(() -> {
          int index = screens.indexOf(displayId);
          if (index > -1) {
            screens.remove(index);
          }
          try {
            boolean flags = isSecureFlag();
            sendEvent(CaptureProtectionConstant.LISTENER_EVENT_NAME, flags, flags,
                !screens.isEmpty()
                    ? CaptureProtectionConstant.CaptureProtectionModuleStatus.RECORD_DETECTED_START.ordinal()
                    : CaptureProtectionConstant.CaptureProtectionModuleStatus.RECORD_DETECTED_END.ordinal());
            Log.d(NAME, "=> display remove event " + displayId);
          } catch (Exception e) {
            Log.e(NAME, "display remove event Error with displayId: " + displayId + ", error: " + e.getMessage());
          }
        });

      }

      @Override
      public void onDisplayChanged(int displayId) {
        Log.d(NAME, "=> display change event " + displayId);
      }
    }, mainHandler);
  }

  private boolean requestStoragePermission() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      Log.d(NAME, "Permission is granted for under sdk version 23");
      return true;
    }

    if (Build.VERSION.SDK_INT < 34) {
      // TODO: Android 14 didn't require storage permission, use
      // android.permission.DETECT_SCREEN_CAPTURE instead.
    }

    String requestPermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        ? Manifest.permission.READ_MEDIA_IMAGES
        : Manifest.permission.READ_EXTERNAL_STORAGE;

    if (ContextCompat.checkSelfPermission(
        reactContext.getCurrentActivity(), requestPermission) == PackageManager.PERMISSION_GRANTED) {
      Log.d(NAME, "Permission is granted");
      return true;
    } else {
      Log.d(NAME, "Permission is revoked");
      ActivityCompat.requestPermissions(reactContext.getCurrentActivity(), new String[] { requestPermission }, 1);
      return false;
    }
  }

  private void addListener() {
    if (contentObserver == null) {
      requestStoragePermission();
      contentObserver = new ContentObserver(mainHandler) {
        @Override
        public void onChange(boolean selfChange, Uri uri) {
          Log.d(NAME, "contentObserver onChange " + uri.toString());
          if (uri.toString().matches(MediaStore.Images.Media.EXTERNAL_CONTENT_URI.toString() + "/[0-9]+")) {

            Cursor cursor = null;
            try {
              cursor = reactContext.getContentResolver().query(uri, new String[] {
                  MediaStore.Images.Media.DATA
              }, null, null, null);

              if (cursor != null && cursor.moveToFirst()) {
                final String path = cursor.getString(cursor.getColumnIndex(MediaStore.Images.Media.DATA));
                if (path != null && path.toLowerCase().contains("screenshots")) {
                  Log.d(NAME, "contentObserver detect screenshot file" + path);
                  boolean flags = isSecureFlag();
                  sendEvent(CaptureProtectionConstant.LISTENER_EVENT_NAME, flags, flags,
                      CaptureProtectionConstant.CaptureProtectionModuleStatus.CAPTURE_DETECTED.ordinal());

                }
              }
            } finally {
              if (cursor != null) {
                cursor.close();
              }
            }
          }
          super.onChange(selfChange, uri);
        }
      };
      reactContext.getContentResolver().registerContentObserver(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true,
          contentObserver);
    }
  }

  private void removeListener() {
    if (contentObserver != null) {
      reactContext.getContentResolver().unregisterContentObserver(contentObserver);
    }
  }

  private boolean isSecureFlag() {
    return (reactContext.getCurrentActivity().getWindow().getAttributes().flags
        & WindowManager.LayoutParams.FLAG_SECURE) != 0;
  }

  private void sendEvent(String eventName, WritableMap params) {
    Log.d(NAME, "send event \'" + eventName + "\' params: " + params.toString());
    this.reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
  }

  private void sendEvent(String eventName, boolean preventRecord, boolean preventScreenshot, int status) {
    WritableMap params = Arguments.createMap();
    params.putMap("isPrevent", createPreventStatusMap(preventScreenshot, preventRecord));
    params.putInt("status", status);
    Log.d(NAME, "send event \'" + eventName + "\' params: " + params.toString());
    this.reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
  }

  private WritableMap createPreventStatusMap(boolean screenshot, boolean recordScreen) {
    WritableMap statusMap = Arguments.createMap();
    statusMap.putBoolean("screenshot", screenshot);
    statusMap.putBoolean("record", recordScreen);
    return statusMap;
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void addScreenshotListener() {
    addListener();
  }

  @ReactMethod
  public void removeScreenshotListener() {
    removeListener();
  }

  @ReactMethod
  public void hasListener(Promise promise) {
    runOnUiThread(() -> {
      try {
        WritableMap params = createPreventStatusMap(contentObserver != null, false);
        promise.resolve(params);
      } catch (Exception e) {
        promise.reject("hasListener", e);
      }
    });
  }

  @ReactMethod
  public void isScreenRecording(Promise promise) {
    runOnUiThread(() -> {
      try {
        promise.resolve(screens.size() > 1);
      } catch (Exception e) {
        promise.reject("preventScreenshot", e);
      }
    });
  }

  @ReactMethod
  public void preventScreenshot(Promise promise) {
    runOnUiThread(() -> {
      try {
        reactContext.getCurrentActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);

        sendEvent(CaptureProtectionConstant.LISTENER_EVENT_NAME, true, true,
            CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal());
        addListener();
        promise.resolve(true);
      } catch (Exception e) {
        promise.reject("preventScreenshot", e);
      }
    });
  }

  @ReactMethod
  public void allowScreenshot(Boolean removeListener, Promise promise) {
    runOnUiThread(() -> {
      try {
        reactContext.getCurrentActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);

        sendEvent(CaptureProtectionConstant.LISTENER_EVENT_NAME, false, false,
            CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal());
        if (removeListener == true) {
          removeListener();
        }
        promise.resolve(true);
      } catch (Exception e) {
        promise.reject("allowScreenshot", e);
      }
    });
  }

  @ReactMethod
  public void getPreventStatus(Promise promise) {
    runOnUiThread(() -> {
      try {
        boolean flags = isSecureFlag();
        WritableMap statusMap = createPreventStatusMap(flags, flags);

        promise.resolve(statusMap);
      } catch (Exception e) {
        promise.reject("getPreventStatus", e);
      }
    });
  }

  @ReactMethod
  public void requestPermission(Promise promise) {
    boolean isPermission = requestStoragePermission();
    promise.resolve(isPermission);
    return;
  }
}
