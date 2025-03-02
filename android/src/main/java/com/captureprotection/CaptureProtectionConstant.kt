package com.captureprotection

class CaptureProtectionConstant {
    companion object {
        const val LISTENER_EVENT_NAME = "CaptureProtectionListener"
        const val NAME = "CaptureProtection"
    }
    enum class CaptureProtectionModuleStatus {
        /** @deprecated create record listener to use `addRecordCaptureProtecter` */
        INIT_RECORD_LISTENER,

        /** @deprecated remove record listener to use `removeRecordCaptureProtecter` */
        REMOVE_RECORD_LISTENER,

        /**
         * @deprecated try to remove listener for `removeRecordCaptureProtecter`, but listener is
         * not exist
         */
        RECORD_LISTENER_NOT_EXIST,

        /**
         * @deprecated try to add listener for `addRecordCaptureProtecter`, but listener is already
         * exist
         */
        RECORD_LISTENER_EXIST,

        /** listener detect `isCaptured` is `true` */
        RECORD_DETECTED_START,

        /** listener detect `isCaptured` is `false` */
        RECORD_DETECTED_END,

        /** when `UIApplicationUserDidTakeScreenshotNotification` observer called */
        CAPTURE_DETECTED,
        UNKNOWN
    }
}
