package com.captureprotection

import android.view.WindowManager
import com.captureprotection.constants.CaptureEventType
import com.captureprotection.constants.Constants
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = Constants.NAME)
class CaptureProtectionModule(private val reactContext: ReactApplicationContext) :
  CaptureProtectionModuleSpec(reactContext) {
    
  override fun getName() = Constants.NAME

  @ReactMethod
  fun addListener(eventName: String) {
    super.addScreenCaptureListener()
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    // super.removeScreenCaptureListener()
  }

  @ReactMethod
  override fun hasListener(promise: Promise) {
    getCurrentActivity()?.runOnUiThread {
      try {
        val params = super.hasScreenCaptureListener()
        promise.resolve(params)
      } catch (e: Exception) {
        promise.reject("hasListener", e)
      }
    }
  }

  @ReactMethod
  override fun isScreenRecording(promise: Promise) {
    getCurrentActivity()?.runOnUiThread {
      try {
        promise.resolve(super.screens.size > 1)
      } catch (e: Exception) {
        promise.reject("isScreenRecording", e)
      }
    }
  }

  @ReactMethod
  override fun prevent(promise: Promise) {
    getCurrentActivity()?.runOnUiThread {
      try {
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(
                reactContext,
                Constants.LISTENER_EVENT_NAME,
                CaptureEventType.PREVENT_SCREEN_CAPTURE.value +
                        CaptureEventType.PREVENT_SCREEN_RECORDING.value +
                        CaptureEventType.PREVENT_SCREEN_APP_SWITCHING.value
        )
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("prevent", e)
      }
    }
  }

  @ReactMethod
  override fun allow(promise: Promise) {
    getCurrentActivity()?.runOnUiThread {
      try {
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(
                reactContext,
                Constants.LISTENER_EVENT_NAME,
                CaptureEventType.ALLOW.value
        )
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("allow", e)
      }
    }
  }

  @ReactMethod
  override fun protectionStatus(promise: Promise) {
    getCurrentActivity()?.runOnUiThread {
      try {
        val flags = ActivityUtils.isSecureFlag(reactContext)
        promise.resolve(flags)
      } catch (e: Exception) {
        promise.reject("protectionStatus", e)
      }
    }
  }

  @ReactMethod
  override fun requestPermission(promise: Promise) {
    val isPermission = super.requestStoragePermission()
    promise.resolve(isPermission)
  }

  @ReactMethod
  override fun checkPermission(promise: Promise) {
    val isPermission = super.checkStoragePermission()
    promise.resolve(isPermission)
  }
}
