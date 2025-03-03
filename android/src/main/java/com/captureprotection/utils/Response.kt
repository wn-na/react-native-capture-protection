package com.captureprotection

import com.facebook.react.bridge.*
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

class Response {
    companion object {
        fun createPreventMap(screenshot: Boolean, recordScreen: Boolean): WritableMap {
            return Arguments.createMap().apply {
                putBoolean("screenshot", screenshot)
                putBoolean("record", recordScreen)
            }
        }

        fun createPreventWithStatusMap(
                status: Int,
                screenshot: Boolean,
                recordScreen: Boolean
        ): WritableMap {
            return Arguments.createMap().apply {
                putMap("isPrevent", Response.createPreventMap(screenshot, recordScreen))
                putInt("status", status)
            }
        }

        fun sendEvent(
                reactContext: ReactApplicationContext,
                eventName: String,
                params: WritableMap
        ) {
            reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit(eventName, params)
        }

        fun sendEvent(reactContext: ReactApplicationContext, eventName: String, status: Int) {
            val flag = ActivityUtils.isSecureFlag(reactContext)
            val params = Response.createPreventWithStatusMap(status, flag, flag)
            sendEvent(reactContext, eventName, params)
        }
    }
}
