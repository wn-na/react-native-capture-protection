package com.captureprotection.constants

import android.Manifest
import android.os.Build
import com.facebook.react.bridge.*

class Constants {
    companion object {
        const val LISTENER_EVENT_NAME = "CaptureProtectionListener"
        const val NAME = "CaptureProtection"
        val requestPermission: String =
                if (Build.VERSION.SDK_INT >= 33) {
                    "android.permission.READ_MEDIA_IMAGES"
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
    }
}
