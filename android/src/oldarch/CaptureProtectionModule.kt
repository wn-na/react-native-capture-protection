package com.captureprotection

import com.facebook.react.bridge.ActivityEventListener
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.Promise

abstract class CaptureProtectionModuleSpec internal constructor(context: ReactApplicationContext) :
CaptureProtectionLifecycleListener(context) {
  abstract fun hasListener(promise: Promise)
  abstract fun isScreenRecording(promise: Promise)
  abstract fun prevent(promise: Promise)
  abstract fun allow(promise: Promise)
  abstract fun protectionStatus(promise: Promise)
  abstract fun requestPermission(promise: Promise)
  abstract fun checkPermission(promise: Promise)
}