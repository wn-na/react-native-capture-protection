package com.captureprotection

import com.facebook.react.bridge.ActivityEventListener
import com.facebook.react.bridge.ReactApplicationContext
import com.captureprotection.constants.Constants

abstract class CaptureProtectionModuleSpec internal constructor(context: ReactApplicationContext) :
  NativeCaptureProtectionSpec(context) {
}