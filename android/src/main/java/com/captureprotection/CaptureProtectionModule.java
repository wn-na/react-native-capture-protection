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
import android.os.Message;
import android.provider.MediaStore;
import android.util.Log;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.captureprotection.Utils;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.LifecycleEventListener;

import java.lang.reflect.*;
import java.util.ArrayList;
import java.util.List;

@ReactModule(name = CaptureProtectionConstant.NAME)
public class CaptureProtectionModule extends ReactContextBaseJavaModule implements LifecycleEventListener {
  private static final String NAME = CaptureProtectionConstant.NAME;
  private final ReactApplicationContext reactContext;
  // DisplayManager is Add API level 17
  private final DisplayManager displayManager;
  private final DisplayManager.DisplayListener displayListener;

  private final String requestPermission = Build.VERSION.SDK_INT >= 33 // Build.VERSION_CODES.TIRAMISU
      ? "android.permission.READ_MEDIA_IMAGES" // Manifest.permission.READ_MEDIA_IMAGES
      : Manifest.permission.READ_EXTERNAL_STORAGE;

  private List<Integer> screens = new ArrayList<>();
  private ContentObserver contentObserver = null;

  // Activity.ScreenCaptureCallback is Add API level 34
  public static Object screenCaptureCallback = null;

  private Activity getReactCurrentActivity() {
    return reactContext.getCurrentActivity();
  }

  private Method getScreenCaptureCallback() {
    if (Build.VERSION.SDK_INT < 34) {
      return null;
    }
    return Utils.getMethod(getReactCurrentActivity().getClass(), "registerScreenCaptureCallback");
  }

  public void createCaptureCallback() {
    if (Build.VERSION.SDK_INT < 34) {
      Log.d(NAME, "under Android 14 is not supported");
      return;
    }
    if (screenCaptureCallback != null) {
      return;
    }
    try {
      for (Class clazz : new Activity().getClass().getDeclaredClasses()) {
        if (clazz.getSimpleName().equals("ScreenCaptureCallback")) {
          Class ScreenCaptureCallback = clazz;
          Object dynamic = (Object) Proxy.newProxyInstance(
              ScreenCaptureCallback.getClassLoader(), new Class<?>[] { ScreenCaptureCallback },
              new InvocationHandler() {
                @Override
                public Object invoke(Object proxy, Method m, Object[] args) throws Throwable {
                  if (m.getName().equals("onScreenCaptured")) {
                    try {
                      Log.d(NAME, "=> capture onScreenCaptured add event ");
                      boolean flags = isSecureFlag();
                      sendEvent(
                          CaptureProtectionConstant.LISTENER_EVENT_NAME,
                          flags,
                          flags,
                          CaptureProtectionConstant.CaptureProtectionModuleStatus.CAPTURE_DETECTED.ordinal());
                    } catch (Exception e) {
                      Log.e(NAME, "onScreenCaptured has raise Exception: " + e.getLocalizedMessage());
                    }
                    return null;
                  }

                  return m.invoke(ScreenCaptureCallback, args);
                }
              });
          screenCaptureCallback = dynamic;
          break;
        }
      }

    } catch (Exception e) {
      Log.e(NAME, "createCaptureCallback has raise Exception: " + e.getLocalizedMessage());
    }
  }

  public CaptureProtectionModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;

    displayManager = (DisplayManager) reactContext.getSystemService(Context.DISPLAY_SERVICE);
    createCaptureCallback();
    displayListener = new DisplayManager.DisplayListener() {
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
    };

    displayManager.registerDisplayListener(displayListener, Utils.MainHandler.INSTANCE);
    reactContext.addLifecycleEventListener(this);
  }

  @Override
  public void onHostResume() {
    try {
      Method registerScreenCaptureCallback = getScreenCaptureCallback();
      if (registerScreenCaptureCallback != null) {
        if (screenCaptureCallback == null) {
          createCaptureCallback();
        }
        registerScreenCaptureCallback.invoke(
            getReactCurrentActivity(),
            Utils.MainExecutor.INSTANCE,
            (Object) screenCaptureCallback);
      }
    } catch (Exception e) {
      Log.e(NAME, "onHostResume has raise Exception: " + e.getLocalizedMessage());
    }
  }

  @Override
  public void onHostPause() {
  }

  @Override
  public void onHostDestroy() {
    try {
      if (Build.VERSION.SDK_INT >= 34) {
        Method method = Utils.getMethod(
            getReactCurrentActivity().getClass(),
            "unregisterScreenCaptureCallback");
        if (method != null && screenCaptureCallback != null) {
          method.invoke(getReactCurrentActivity(), (Object) screenCaptureCallback);
        }
      }
    } catch (Exception e) {
      Log.e(NAME, "onHostDestroy has raise Exception: " + e.getLocalizedMessage());
    }
  }

  private boolean checkStoragePermission() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      return true;
    }

    if (getScreenCaptureCallback() != null) {
      return true;
    }

    try {
      if (getReactCurrentActivity() == null) {
        return false;
      }

      return (ContextCompat.checkSelfPermission(getReactCurrentActivity(),
          requestPermission) == PackageManager.PERMISSION_GRANTED);
    } catch (Exception e) {
      Log.e(NAME, "checkStoragePermission has raise Exception: " + e.getLocalizedMessage());
      return false;
    }
  }

  private boolean requestStoragePermission() {
    try {
      boolean isGranted = checkStoragePermission();
      if (getReactCurrentActivity() == null) {
        return false;
      }
      if (isGranted) {
        Log.d(NAME, "Permission is granted");
        return true;
      }

      Log.d(NAME, "Permission is revoked");
      ActivityCompat.requestPermissions(getReactCurrentActivity(), new String[] { requestPermission }, 1);
      return false;
    } catch (Exception e) {
      Log.e(NAME, "requestStoragePermission has raise Exception: " + e.getLocalizedMessage());
      return false;
    }
  }

  private void addListener() {
    if (getScreenCaptureCallback() == null) {
      if (contentObserver == null && checkStoragePermission()) {
        contentObserver = new ContentObserver(Utils.MainHandler.INSTANCE) {
          @Override
          public void onChange(boolean selfChange, Uri uri) {
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

        reactContext.getContentResolver().registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            contentObserver);
      }
    } else {
      if (screenCaptureCallback == null) {
        createCaptureCallback();
      }
    }
  }

  private void removeListener() {
    if (contentObserver != null) {
      reactContext.getContentResolver().unregisterContentObserver(contentObserver);
    }
  }

  private boolean isSecureFlag() {
    Activity currentActivity = getReactCurrentActivity();
    if (currentActivity == null) {
      return false;
    }
    return (currentActivity.getWindow().getAttributes().flags
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
    params.putMap("isPrevent", Utils.createPreventStatusMap(preventScreenshot, preventRecord));
    params.putInt("status", status);
    sendEvent(eventName, params);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }

  @ReactMethod
  public void addListener(String eventName) {
    addListener();
  }

  @ReactMethod
  public void removeListeners(Integer count) {
    removeListener();
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
        WritableMap params = Utils.createPreventStatusMap(
            contentObserver != null || getScreenCaptureCallback() != null,
            displayListener != null);
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
        Activity currentActivity = getReactCurrentActivity();
        if (currentActivity == null) {
          Log.w(NAME, "preventScreenshot: Current Activity is null");
          return;
        }
        currentActivity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);

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
        Activity currentActivity = getReactCurrentActivity();
        if (currentActivity == null) {
          Log.w(NAME, "allowScreenshot: Current Activity is null");
          return;
        }
        currentActivity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);

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
        WritableMap statusMap = Utils.createPreventStatusMap(flags, flags);
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

  @ReactMethod
  public void checkPermission(Promise promise) {
    boolean isPermission = checkStoragePermission();
    promise.resolve(isPermission);
    return;
  }
}
