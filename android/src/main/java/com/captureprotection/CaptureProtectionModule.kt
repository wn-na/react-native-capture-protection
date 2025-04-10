package com.captureprotection

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
    super.addScreenCaptureListener()
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    super.removeScreenCaptureListener()
  }

  @ReactMethod
  fun addScreenshotListener() {
    super.addScreenCaptureListener()
  }

  @ReactMethod
  fun removeScreenshotListener() {
    super.removeScreenCaptureListener()
  }

  @ReactMethod
  fun hasListener(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val params =
                Response.createPreventMap(
                        super.hasScreenCaptureListener(),
                        super.hasScreenRecordListener()
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
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(reactContext, Constants.LISTENER_EVENT_NAME, StatusCode.UNKNOWN.ordinal)
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("preventScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun allowScreenshot(removeListener: Boolean, promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(reactContext, Constants.LISTENER_EVENT_NAME, StatusCode.UNKNOWN.ordinal)
        if (removeListener) {
          super.removeScreenCaptureListener()
        }
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("allowScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun getPreventStatus(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val flags = ActivityUtils.isSecureFlag(reactContext)
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
