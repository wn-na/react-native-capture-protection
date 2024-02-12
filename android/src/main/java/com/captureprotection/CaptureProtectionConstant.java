package com.captureprotection;

import androidx.annotation.NonNull;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.view.WindowManager;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import static com.facebook.react.bridge.UiThreadUtil.runOnUiThread;

public class CaptureProtectionConstant {
  public static final String LISTENER_EVENT_NAME = "CaptureProtectionListener";
  public static final String NAME = "CaptureProtection";

  public enum CaptureProtectionModuleStatus {
    /** @deprecated create record listener to use `addRecordCaptureProtecter` */
    INIT_RECORD_LISTENER,
    /** @deprecated remove record listener to use `removeRecordCaptureProtecter` */
    REMOVE_RECORD_LISTENER,
    /**
     * @deprecated try to remove listener for `removeRecordCaptureProtecter`, but
     *             listener is not exist
     */
    RECORD_LISTENER_NOT_EXIST,
    /**
     * @deprecated try to add listener for `addRecordCaptureProtecter`, but listener
     *             is already exist
     */
    RECORD_LISTENER_EXIST,
    /** listener detect `isCaptured` is `true` */
    RECORD_DETECTED_START,
    /** listener detect `isCaptured` is `false` */
    RECORD_DETECTED_END,
    /** when `UIApplicationUserDidTakeScreenshotNotification` observer called */
    CAPTURE_DETECTED,
    UNKNOWN,
  }
}
