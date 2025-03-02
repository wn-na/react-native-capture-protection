package com.captureprotection

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.hardware.display.DisplayManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.captureprotection.constants.Constants
import com.captureprotection.constants.StatusCode
import com.captureprotection.utils.ModuleThread
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import java.util.ArrayList

open class CaptureProtectionLifecycleListener(
        private val reactContext: ReactApplicationContext,
) : ReactContextBaseJavaModule(reactContext), LifecycleEventListener {

    override fun getName() = Constants.NAME
    val displayManager: DisplayManager =
            reactContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    val displayListener: DisplayManager.DisplayListener
    val requestPermission =
            if (Build.VERSION.SDK_INT >= 33) "android.permission.READ_MEDIA_IMAGES"
            else Manifest.permission.READ_EXTERNAL_STORAGE
    val screens = ArrayList<Int>()

    companion object {
        var screenCaptureCallback: Any? = null
        var contentObserver: ContentObserver? = null
    }

    fun getReactCurrentActivity(): Activity? {
        return reactContext.currentActivity
    }

    fun getScreenCaptureCallback(): Method? {
        if (Build.VERSION.SDK_INT < 34) {
            return null
        }
        return Reflection.getMethod(
                getReactCurrentActivity()!!.javaClass,
                "registerScreenCaptureCallback"
        )
    }

    fun createCaptureCallback() {
        if (Build.VERSION.SDK_INT < 34) {
            Log.d(Constants.NAME, "under Android 14 is not supported")
            return
        }
        if (CaptureProtectionLifecycleListener.screenCaptureCallback != null) {
            return
        }
        try {
            for (clazz in Activity::class.java.declaredClasses) {
                if (clazz.simpleName == "ScreenCaptureCallback") {
                    val dynamic =
                            Proxy.newProxyInstance(
                                    clazz.classLoader,
                                    arrayOf(clazz),
                                    InvocationHandler { proxy, m, args ->
                                        if (m.name == "onScreenCaptured") {
                                            try {
                                                Log.d(
                                                        Constants.NAME,
                                                        "=> capture onScreenCaptured add event "
                                                )
                                                val flags = isSecureFlag()
                                                sendEvent(
                                                        Constants.LISTENER_EVENT_NAME,
                                                        flags,
                                                        flags,
                                                        StatusCode.CAPTURE_DETECTED.ordinal
                                                )
                                            } catch (e: Exception) {
                                                Log.e(
                                                        Constants.NAME,
                                                        "onScreenCaptured has raise Exception: " +
                                                                e.localizedMessage
                                                )
                                            }
                                            return@InvocationHandler null
                                        }
                                        m.invoke(proxy, *args)
                                    }
                            )
                    CaptureProtectionLifecycleListener.screenCaptureCallback = dynamic
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(
                    Constants.NAME,
                    "createCaptureCallback has raise Exception: " + e.localizedMessage
            )
        }
    }

    init {
        createCaptureCallback()
        displayListener =
                object : DisplayManager.DisplayListener {
                    override fun onDisplayAdded(displayId: Int) {
                        getReactCurrentActivity()?.runOnUiThread {
                            if (displayManager.getDisplay(displayId) == null) {
                                screens.add(displayId)
                            }
                            try {
                                val flags = isSecureFlag()
                                sendEvent(
                                        Constants.LISTENER_EVENT_NAME,
                                        flags,
                                        flags,
                                        if (screens.isEmpty()) StatusCode.UNKNOWN.ordinal
                                        else StatusCode.RECORD_DETECTED_START.ordinal
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
                        getReactCurrentActivity()?.runOnUiThread {
                            val index = screens.indexOf(displayId)
                            if (index > -1) {
                                screens.removeAt(index)
                            }
                            try {
                                val flags = isSecureFlag()
                                sendEvent(
                                        Constants.LISTENER_EVENT_NAME,
                                        flags,
                                        flags,
                                        if (screens.isNotEmpty())
                                                StatusCode.RECORD_DETECTED_START.ordinal
                                        else StatusCode.RECORD_DETECTED_END.ordinal
                                )
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
        displayManager.registerDisplayListener(displayListener, ModuleThread.MainHandler)
        reactContext.addLifecycleEventListener(this)
    }

    override fun onHostResume() {
        try {
            val registerScreenCaptureCallback = getScreenCaptureCallback()
            if (registerScreenCaptureCallback != null) {
                if (CaptureProtectionLifecycleListener.screenCaptureCallback == null) {
                    createCaptureCallback()
                }
                registerScreenCaptureCallback.invoke(
                        getReactCurrentActivity(),
                        ModuleThread.MainExecutor,
                        CaptureProtectionLifecycleListener.screenCaptureCallback
                )
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostResume has raise Exception: " + e.localizedMessage)
        }
    }

    override fun onHostPause() {}

    override fun onHostDestroy() {
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                val method =
                        Reflection.getMethod(
                                getReactCurrentActivity()!!.javaClass,
                                "unregisterScreenCaptureCallback"
                        )
                if (method != null &&
                                CaptureProtectionLifecycleListener.screenCaptureCallback != null
                ) {
                    method.invoke(
                            getReactCurrentActivity(),
                            CaptureProtectionLifecycleListener.screenCaptureCallback
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(Constants.NAME, "onHostDestroy has raise Exception: " + e.localizedMessage)
        }
    }

    fun sendEvent(eventName: String, params: WritableMap) {
        Log.d(Constants.NAME, "send event '$eventName' params: $params")
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(eventName, params)
    }

    fun sendEvent(
            eventName: String,
            preventRecord: Boolean,
            preventScreenshot: Boolean,
            status: Int
    ) {
        val params = Response.createPreventWithStatusMap(status, preventScreenshot, preventRecord)
        sendEvent(eventName, params)
    }

    fun checkStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        if (getScreenCaptureCallback() != null) {
            return true
        }
        return try {
            getReactCurrentActivity()?.let {
                ContextCompat.checkSelfPermission(it, requestPermission) ==
                        PackageManager.PERMISSION_GRANTED
            }
                    ?: false
        } catch (e: Exception) {
            Log.e(
                    Constants.NAME,
                    "checkStoragePermission has raise Exception: " + e.localizedMessage
            )
            false
        }
    }

    fun requestStoragePermission(): Boolean {
        return try {
            val isGranted = checkStoragePermission()
            if (getReactCurrentActivity() == null) {
                return false
            }
            if (isGranted) {
                Log.d(Constants.NAME, "Permission is granted")
                return true
            }
            Log.d(Constants.NAME, "Permission is revoked")
            ActivityCompat.requestPermissions(
                    getReactCurrentActivity()!!,
                    arrayOf(requestPermission),
                    1
            )
            false
        } catch (e: Exception) {
            Log.e(
                    Constants.NAME,
                    "requestStoragePermission has raise Exception: " + e.localizedMessage
            )
            false
        }
    }

    fun addListener() {
        if (getScreenCaptureCallback() == null) {
            if (CaptureProtectionLifecycleListener.contentObserver == null &&
                            checkStoragePermission()
            ) {
                CaptureProtectionLifecycleListener.contentObserver =
                        object : ContentObserver(ModuleThread.MainHandler) {
                            override fun onChange(selfChange: Boolean, uri: Uri?) {
                                if (uri != null &&
                                                uri.toString()
                                                        .matches(
                                                                Regex(
                                                                        MediaStore.Images.Media
                                                                                .EXTERNAL_CONTENT_URI
                                                                                .toString() +
                                                                                "/[0-9]+"
                                                                )
                                                        )
                                ) {
                                    var cursor: Cursor? = null
                                    try {
                                        cursor =
                                                reactContext.contentResolver.query(
                                                        uri,
                                                        arrayOf(MediaStore.Images.Media.DATA),
                                                        null,
                                                        null,
                                                        null
                                                )
                                        if (cursor != null && cursor.moveToFirst()) {
                                            val path =
                                                    cursor.getString(
                                                            cursor.getColumnIndex(
                                                                    MediaStore.Images.Media.DATA
                                                            )
                                                    )
                                            if (path != null &&
                                                            path.toLowerCase()
                                                                    .contains("screenshots")
                                            ) {
                                                Log.d(
                                                        Constants.NAME,
                                                        "CaptureProtectionLifecycleListener.contentObserver detect screenshot file$path"
                                                )
                                                val flags = isSecureFlag()
                                                sendEvent(
                                                        Constants.LISTENER_EVENT_NAME,
                                                        flags,
                                                        flags,
                                                        StatusCode.CAPTURE_DETECTED.ordinal
                                                )
                                            }
                                        }
                                    } finally {
                                        cursor?.close()
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
        } else {
            if (CaptureProtectionLifecycleListener.screenCaptureCallback == null) {
                createCaptureCallback()
            }
        }
    }

    fun removeListener() {
        CaptureProtectionLifecycleListener.contentObserver?.let {
            reactContext.contentResolver.unregisterContentObserver(it)
        }
    }

    fun isSecureFlag(): Boolean {
        val currentActivity = getReactCurrentActivity()
        return currentActivity?.window?.attributes?.flags?.and(
                WindowManager.LayoutParams.FLAG_SECURE
        ) != 0
    }
}
