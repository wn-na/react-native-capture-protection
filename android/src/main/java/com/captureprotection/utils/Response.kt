package com.captureprotection

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap

class Response() {
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
    }
}
