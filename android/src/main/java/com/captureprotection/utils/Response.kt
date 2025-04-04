package com.captureprotection

import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule

class Response {
    companion object {
        fun sendEvent(reactContext: ReactApplicationContext, eventName: String, status: Int) {
            reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit(eventName, status)
        }
    }
}
