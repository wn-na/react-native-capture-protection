package com.captureprotection

import android.app.Activity
import android.view.WindowManager
import com.facebook.react.bridge.*

class ActivityUtils {
    companion object {
        fun getReactCurrentActivity(reactContext: ReactApplicationContext): Activity? {
            return reactContext.currentActivity
        }

        fun isSecureFlag(reactContext: ReactApplicationContext): Boolean {
            val currentActivity = getReactCurrentActivity(reactContext)
            return currentActivity?.window?.attributes?.flags?.and(
                    WindowManager.LayoutParams.FLAG_SECURE
            ) != 0
        }
    }
}
