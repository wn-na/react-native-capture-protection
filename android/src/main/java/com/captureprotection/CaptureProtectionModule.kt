package com.captureprotection

import android.util.Log
import android.view.WindowManager
import com.captureprotection.constants.Constants
import com.captureprotection.constants.StatusCode
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = Constants.NAME)
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
        val screenshotListener =
                CaptureProtectionLifecycleListener.contentObserver != null ||
                        super.getScreenCaptureCallback() != null
        val recordListener = super.displayListener != null
        val params = Response.createPreventMap(screenshotListener, recordListener)
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
          Log.w(Constants.NAME, "preventScreenshot: Current Activity is null")
        } else {
          currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          super.sendEvent(Constants.LISTENER_EVENT_NAME, StatusCode.UNKNOWN.ordinal)
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
          Log.w(Constants.NAME, "allowScreenshot: Current Activity is null")
        } else {
          currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          super.sendEvent(Constants.LISTENER_EVENT_NAME, StatusCode.UNKNOWN.ordinal)
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
        val statusMap = Response.createPreventMap(flags, flags)
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
