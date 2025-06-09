package com.captureprotection

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.captureprotection.constants.CaptureEventType
import com.captureprotection.constants.Constants
import com.captureprotection.utils.FileUtils
import com.captureprotection.utils.ModuleThread
import com.facebook.react.bridge.*
import java.lang.reflect.Method
import java.util.ArrayList
import kotlinx.coroutines.*

open class CaptureProtectionLifecycleListener(
        private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), LifecycleEventListener {

    override fun getName() = Constants.NAME

    val displayManager: DisplayManager =
            reactContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    val screens = ArrayList<Int>()
    val reactCurrentActivity: Activity?
        get() = ActivityUtils.getReactCurrentActivity(reactContext)
    var eventJob: Job? = null

    companion object {
        var screenCaptureCallback: Any? = null
        var registerScreenCaptureCallback: Method? = null
        var unregisterScreenCaptureCallback: Method? = null

        var contentObserver: ContentObserver? = null
        var displayListener: DisplayManager.DisplayListener? = null
        var reactContext: ReactApplicationContext? = null
    }

    fun reflectionCallback() {
        if (Build.VERSION.SDK_INT < 34) {
            return
        }
        if (reactCurrentActivity == null) {
            return
        }

        if (CaptureProtectionLifecycleListener.registerScreenCaptureCallback == null) {
            CaptureProtectionLifecycleListener.registerScreenCaptureCallback =
                    Reflection.getMethod(
                            reactCurrentActivity!!.javaClass,
                            "registerScreenCaptureCallback"
                    )
        }

        if (CaptureProtectionLifecycleListener.unregisterScreenCaptureCallback == null) {
            CaptureProtectionLifecycleListener.unregisterScreenCaptureCallback =
                    Reflection.getMethod(
                            reactCurrentActivity!!.javaClass,
                            "unregisterScreenCaptureCallback"
                    )
        }

        if (CaptureProtectionLifecycleListener.screenCaptureCallback == null ||
                        CaptureProtectionLifecycleListener.reactContext != reactContext
        ) {
            CaptureProtectionLifecycleListener.screenCaptureCallback =
                    Reflection.createScreenCaptureCallback {
                        triggerCaptureEvent(CaptureEventType.CAPTURED)
                    }
        }
    }

    fun triggerCaptureEvent(type: CaptureEventType) {
        eventJob?.cancel()
        eventJob =
                CoroutineScope(Dispatchers.Main).launch {
                    try {
                        Response.sendEvent(reactContext, Constants.LISTENER_EVENT_NAME, type.value)
                        delay(1000)
                        if (screens.isNotEmpty()) {
                            Response.sendEvent(
                                    reactContext,
                                    Constants.LISTENER_EVENT_NAME,
                                    CaptureEventType.RECORDING.value
                            )
                        } else {
                            Response.sendEvent(
                                    reactContext,
                                    Constants.LISTENER_EVENT_NAME,
                                    CaptureEventType.NONE.value
                            )
                        }
                    } catch (e: Exception) {
                        Log.e(Constants.NAME, "Error in triggerCaptureEvent: ${e.message}")
                    }
                }
    }

    fun registerDisplayListener() {
        if (CaptureProtectionLifecycleListener.displayListener == null ||
                        CaptureProtectionLifecycleListener.reactContext != reactContext
        ) {
            CaptureProtectionLifecycleListener.displayListener =
                    object : DisplayManager.DisplayListener {
                        override fun onDisplayAdded(displayId: Int) {
                            reactCurrentActivity?.runOnUiThread {
                                if (displayManager.getDisplay(displayId) == null) {
                                    screens.add(displayId)
                                }
                                try {
                                    Response.sendEvent(
                                            reactContext,
                                            Constants.LISTENER_EVENT_NAME,
                                            if (screens.isEmpty()) CaptureEventType.NONE.value
                                            else CaptureEventType.RECORDING.value
                                    )
                                    Log.d(Constants.NAME, "=> display add event $displayId")
                                } catch (e: Exception) {
                                    Log.e(
                                            Constants.NAME,
                                            "display add event Error with displayId: $displayId, error: ${e.message}"
                                    )
                                }
                            }
                        }

                        override fun onDisplayRemoved(displayId: Int) {
                            reactCurrentActivity?.runOnUiThread {
                                val index = screens.indexOf(displayId)
                                if (index > -1) {
                                    screens.removeAt(index)
                                }
                                try {
                                    if (screens.isEmpty()) {
                                        triggerCaptureEvent(CaptureEventType.END_RECORDING)
                                    } else {
                                        Response.sendEvent(
                                                reactContext,
                                                Constants.LISTENER_EVENT_NAME,
                                                CaptureEventType.RECORDING.value
                                        )
                                    }
                                    Log.d(Constants.NAME, "=> display remove event $displayId")
                                } catch (e: Exception) {
                                    Log.e(
                                            Constants.NAME,
                                            "display remove event Error with displayId: $displayId, error: ${e.message}"
                                    )
                                }
                            }
                        }

                        override fun onDisplayChanged(displayId: Int) {
                            Log.d(Constants.NAME, "=> display change event $displayId")
                        }
                    }
        }
    }

    init {
        if (CaptureProtectionLifecycleListener.reactContext != reactContext) {
            CaptureProtectionLifecycleListener.screenCaptureCallback = null
        }
        reflectionCallback()
        registerDisplayListener()
        displayManager.registerDisplayListener(
                CaptureProtectionLifecycleListener.displayListener,
                ModuleThread.MainHandler
        )
        CaptureProtectionLifecycleListener.reactContext = reactContext
        reactContext.addLifecycleEventListener(this)
    }

    override fun onHostResume() {
        try {
            reflectionCallback()

            CaptureProtectionLifecycleListener.registerScreenCaptureCallback?.let { method ->
                method.invoke(
                        reactCurrentActivity,
                        ModuleThread.MainExecutor,
                        CaptureProtectionLifecycleListener.screenCaptureCallback
                )
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostResume has raise Exception: " + e.message)
        }
    }

    override fun onHostPause() {}

    override fun onHostDestroy() {
        try {
            CaptureProtectionLifecycleListener.unregisterScreenCaptureCallback?.let { method ->
                method.invoke(
                        reactCurrentActivity,
                        CaptureProtectionLifecycleListener.screenCaptureCallback
                )
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostDestroy has raise Exception: " + e.localizedMessage)
        }
    }

    fun checkStoragePermission(): Boolean {
        return when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M -> true
            CaptureProtectionLifecycleListener.registerScreenCaptureCallback != null -> true
            else -> checkPermission()
        }
    }

    private fun checkPermission(): Boolean {
        return if (BuildConfig.FLAVOR == "fullMediaCapture") {
            try {
                reactCurrentActivity?.let {
                    ContextCompat.checkSelfPermission(it, Constants.requestPermission) ==
                            PackageManager.PERMISSION_GRANTED
                }
                        ?: false
            } catch (e: Exception) {
                Log.e(
                        Constants.NAME,
                        "checkStoragePermission raised Exception: ${e.localizedMessage}"
                )
                false
            }
        } else {
            false
        }
    }

    fun requestStoragePermission(): Boolean {
        return if (BuildConfig.FLAVOR == "fullMediaCapture") {
            try {
                val isGranted = checkStoragePermission()
                if (!isGranted) {
                    Log.d(Constants.NAME, "Permission is revoked")
                    requestPermission()
                    false
                } else {
                    Log.d(Constants.NAME, "Permission is granted")
                    true
                }
            } catch (e: Exception) {
                Log.e(
                        Constants.NAME,
                        "requestStoragePermission raised Exception: ${e.localizedMessage}"
                )
                false
            }
        } else {
            false
        }
    }

    private fun requestPermission() {
        if (BuildConfig.FLAVOR == "fullMediaCapture") {
            reactCurrentActivity?.let {
                ActivityCompat.requestPermissions(it, arrayOf(Constants.requestPermission), 1)
            }
        }
    }

    fun addScreenCaptureListener() {
        reflectionCallback()

        if (CaptureProtectionLifecycleListener.registerScreenCaptureCallback == null) {
            if (CaptureProtectionLifecycleListener.contentObserver == null &&
                            checkStoragePermission()
            ) {
                CaptureProtectionLifecycleListener.contentObserver =
                        object : ContentObserver(ModuleThread.MainHandler) {
                            override fun onChange(selfChange: Boolean, uri: Uri?) {
                                if (FileUtils.isImageUri(uri)) {
                                    if (FileUtils.isScreenshotFile(reactContext, uri!!)) {
                                        Log.d(
                                                Constants.NAME,
                                                "CaptureProtectionLifecycleListener.contentObserver detect screenshot file"
                                        )
                                        triggerCaptureEvent(CaptureEventType.CAPTURED)
                                    }
                                }
                                super.onChange(selfChange, uri)
                            }
                        }
                reactContext.contentResolver.registerContentObserver(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        true,
                        CaptureProtectionLifecycleListener.contentObserver!!
                )
            }
        }
    }

    fun removeScreenCaptureListener() {
        CaptureProtectionLifecycleListener.contentObserver?.let {
            reactContext.contentResolver.unregisterContentObserver(it)
        }
    }

    fun hasScreenCaptureListener(): Boolean {
        return CaptureProtectionLifecycleListener.contentObserver != null ||
                CaptureProtectionLifecycleListener.registerScreenCaptureCallback != null
    }

    fun hasScreenRecordListener(): Boolean {
        return displayListener != null
    }
}
