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
import com.captureprotection.utils.FileUtils
import com.captureprotection.utils.ModuleThread
import com.facebook.react.bridge.*
import java.lang.reflect.Method
import java.util.ArrayList
import kotlinx.coroutines.*
import android.view.WindowManager
import com.captureprotection.constants.CaptureEventType
import com.captureprotection.constants.Constants
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = Constants.NAME)
class CaptureProtectionModule(private val reactContext: ReactApplicationContext) :
CaptureProtectionModuleSpec(reactContext), LifecycleEventListener {

    override fun getName() = NAME

    val displayManager: DisplayManager =
            reactContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager

    val screens = ArrayList<Int>()
    val reactCurrentActivity: Activity?
        get() = ActivityUtils.getReactCurrentActivity(reactContext)
    var eventJob: Job? = null

    companion object {
        const val NAME = Constants.NAME
        const val FULL_MEDIA_CAPTURE_FLAVOR = "fullMediaCapture"
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

        if (CaptureProtectionModule.registerScreenCaptureCallback == null) {
            CaptureProtectionModule.registerScreenCaptureCallback =
                    Reflection.getMethod(
                            reactCurrentActivity!!.javaClass,
                            "registerScreenCaptureCallback"
                    )
        }

        if (CaptureProtectionModule.unregisterScreenCaptureCallback == null) {
            CaptureProtectionModule.unregisterScreenCaptureCallback =
                    Reflection.getMethod(
                            reactCurrentActivity!!.javaClass,
                            "unregisterScreenCaptureCallback"
                    )
        }

        if (CaptureProtectionModule.screenCaptureCallback == null ||
                        CaptureProtectionModule.reactContext != reactContext
        ) {
            CaptureProtectionModule.screenCaptureCallback =
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
        if (CaptureProtectionModule.displayListener == null ||
                        CaptureProtectionModule.reactContext != reactContext
        ) {
            CaptureProtectionModule.displayListener =
                    object : DisplayManager.DisplayListener {
                        override fun onDisplayAdded(displayId: Int) {
                            reactCurrentActivity?.runOnUiThread {
                                if (displayManager.getDisplay(displayId) != null) {
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
        if (CaptureProtectionModule.reactContext != reactContext) {
            CaptureProtectionModule.screenCaptureCallback = null
        }
        reflectionCallback()
        registerDisplayListener()
        displayManager.registerDisplayListener(
                CaptureProtectionModule.displayListener,
                ModuleThread.MainHandler
        )
        CaptureProtectionModule.reactContext = reactContext
        reactContext.addLifecycleEventListener(this)
    }

    override fun onHostResume() {
        try {
            reflectionCallback()

            CaptureProtectionModule.registerScreenCaptureCallback?.let { method ->
                method.invoke(
                        reactCurrentActivity,
                        ModuleThread.MainExecutor,
                        CaptureProtectionModule.screenCaptureCallback
                )
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostResume has raise Exception: " + e.message)
        }
    }

    override fun onHostPause() {}

    override fun onHostDestroy() {
        try {
            CaptureProtectionModule.unregisterScreenCaptureCallback?.let { method ->
                method.invoke(
                        reactCurrentActivity,
                        CaptureProtectionModule.screenCaptureCallback
                )
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostDestroy has raise Exception: " + e.localizedMessage)
        }
    }

    fun checkStoragePermission(): Boolean {
        return when {
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M -> true
            CaptureProtectionModule.registerScreenCaptureCallback != null -> true
            else -> checkPermission()
        }
    }

    private fun checkPermission(): Boolean {
        return if (BuildConfig.FLAVOR == FULL_MEDIA_CAPTURE_FLAVOR) {
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
        return if (BuildConfig.FLAVOR == FULL_MEDIA_CAPTURE_FLAVOR) {
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
        if (BuildConfig.FLAVOR == FULL_MEDIA_CAPTURE_FLAVOR) {
            reactCurrentActivity?.let {
                ActivityCompat.requestPermissions(it, arrayOf(Constants.requestPermission), 1)
            }
        }
    }

    fun addScreenCaptureListener() {
        reflectionCallback()

        if (CaptureProtectionModule.registerScreenCaptureCallback == null) {
            if (CaptureProtectionModule.contentObserver == null &&
                            checkStoragePermission()
            ) {
                CaptureProtectionModule.contentObserver =
                        object : ContentObserver(ModuleThread.MainHandler) {
                            override fun onChange(selfChange: Boolean, uri: Uri?) {
                                if (FileUtils.isImageUri(uri)) {
                                    if (FileUtils.isScreenshotFile(reactContext, uri!!)) {
                                        Log.d(
                                                Constants.NAME,
                                                "CaptureProtectionModule.contentObserver detect screenshot file"
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
                        CaptureProtectionModule.contentObserver!!
                )
            }
        }
    }

    fun removeScreenCaptureListener() {
        CaptureProtectionModule.contentObserver?.let {
            reactContext.contentResolver.unregisterContentObserver(it)
        }
    }

    fun hasScreenCaptureListener(): Boolean {
        return CaptureProtectionModule.contentObserver != null ||
                CaptureProtectionModule.registerScreenCaptureCallback != null
    }

    fun hasScreenRecordListener(): Boolean {
        return displayListener != null
    }

    
  @ReactMethod
  override fun addListener(eventName: String) {
    addScreenCaptureListener()
  }

  @ReactMethod
  override fun removeListeners(count: Double) {
    // removeScreenCaptureListener()
  }

  @ReactMethod
  override fun hasListener(promise: Promise) {
    reactContext.currentActivity?.runOnUiThread {
      try {
        val params = hasScreenCaptureListener()
        promise.resolve(params)
      } catch (e: Exception) {
        promise.reject("hasListener", e)
      }
    }
  }

  @ReactMethod
  override fun isScreenRecording(promise: Promise) {
    reactContext.currentActivity?.runOnUiThread {
      try {
        promise.resolve(screens.size > 1)
      } catch (e: Exception) {
        promise.reject("isScreenRecording", e)
      }
    }
  }

  @ReactMethod
  override fun prevent(promise: Promise) {
    reactContext.currentActivity?.runOnUiThread {
      try {
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(
                reactContext,
                Constants.LISTENER_EVENT_NAME,
                CaptureEventType.PREVENT_SCREEN_CAPTURE.value +
                        CaptureEventType.PREVENT_SCREEN_RECORDING.value +
                        CaptureEventType.PREVENT_SCREEN_APP_SWITCHING.value
        )
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("prevent", e)
      }
    }
  }

  @ReactMethod
  override fun allow(promise: Promise) {
    reactContext.currentActivity?.runOnUiThread {
      try {
        val currentActivity = ActivityUtils.getReactCurrentActivity(reactContext)
        currentActivity!!.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Response.sendEvent(
                reactContext,
                Constants.LISTENER_EVENT_NAME,
                CaptureEventType.ALLOW.value
        )
        promise.resolve(true)
      } catch (e: Exception) {
        promise.reject("allow", e)
      }
    }
  }

  @ReactMethod
  override fun protectionStatus(promise: Promise) {
    reactContext.currentActivity?.runOnUiThread {
      try {
        val flags = ActivityUtils.isSecureFlag(reactContext)
        promise.resolve(flags)
      } catch (e: Exception) {
        promise.reject("protectionStatus", e)
      }
    }
  }

  @ReactMethod
  override fun requestPermission(promise: Promise) {
    val isPermission = requestStoragePermission()
    promise.resolve(isPermission)
  }

  @ReactMethod
  override fun checkPermission(promise: Promise) {
    val isPermission = checkStoragePermission()
    promise.resolve(isPermission)
  }
}
