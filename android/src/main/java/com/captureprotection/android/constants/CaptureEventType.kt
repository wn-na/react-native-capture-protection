package com.captureprotection.android.constants
enum class CaptureEventType(val value: Int) {
    NONE(0),
    RECORDING(1),
    END_RECORDING(2),
    CAPTURED(3),
    APP_SWITCHING(4),
    UNKNOWN(5),
    ALLOW(8),
    PREVENT_SCREEN_CAPTURE(16),
    PREVENT_SCREEN_RECORDING(32),
    PREVENT_SCREEN_APP_SWITCHING(64),
}
