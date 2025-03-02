package com.captureprotection

import android.util.Log
import android.view.WindowManager
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = CaptureProtectionConstant.NAME)
class CaptureProtectionModule(private val reactContext: ReactApplicationContext) :
        CaptureProtectionLifecycleListener(reactContext) {

  @ReactMethod
  fun addListener(eventName: String) {
    super.addListener()
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    super.removeListener()
  }

  @ReactMethod
  fun addScreenshotListener() {
    super.addListener()
  }

  @ReactMethod
  fun removeScreenshotListener() {
    super.removeListener()
  }

  @ReactMethod
  fun hasListener(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val params =
                Utils.createPreventStatusMap(
                        CaptureProtectionLifecycleListener.contentObserver != null ||
                                super.getScreenCaptureCallback() != null,
                        super.displayListener != null
                )
        promise.resolve(params)
      } catch (e: Exception) {
        promise.reject("hasListener", e)
      }
    }
  }

  @ReactMethod
  fun isScreenRecording(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        promise.resolve(super.screens.size > 1)
      } catch (e: Exception) {
        promise.reject("preventScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun preventScreenshot(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val currentActivity = super.getReactCurrentActivity()
        if (currentActivity == null) {
          Log.w(CaptureProtectionConstant.NAME, "preventScreenshot: Current Activity is null")
        } else {
          currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          super.sendEvent(
                  CaptureProtectionConstant.LISTENER_EVENT_NAME,
                  true,
                  true,
                  CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal
          )
          super.addListener()
          promise.resolve(true)
        }
      } catch (e: Exception) {
        promise.reject("preventScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun allowScreenshot(removeListener: Boolean, promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val currentActivity = super.getReactCurrentActivity()
        if (currentActivity == null) {
          Log.w(CaptureProtectionConstant.NAME, "allowScreenshot: Current Activity is null")
        } else {
          currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          super.sendEvent(
                  CaptureProtectionConstant.LISTENER_EVENT_NAME,
                  false,
                  false,
                  CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal
          )
          if (removeListener) {
            super.removeListener()
          }
          promise.resolve(true)
        }
      } catch (e: Exception) {
        promise.reject("allowScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun getPreventStatus(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val flags = super.isSecureFlag()
        val statusMap = Utils.createPreventStatusMap(flags, flags)
        promise.resolve(statusMap)
      } catch (e: Exception) {
        promise.reject("getPreventStatus", e)
      }
    }
  }

  @ReactMethod
  fun requestPermission(promise: Promise) {
    val isPermission = super.requestStoragePermission()
    promise.resolve(isPermission)
  }

  @ReactMethod
  fun checkPermission(promise: Promise) {
    val isPermission = super.checkStoragePermission()
    promise.resolve(isPermission)
  }
}
