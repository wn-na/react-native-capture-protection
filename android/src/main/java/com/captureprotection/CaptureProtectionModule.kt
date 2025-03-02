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
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import java.util.ArrayList

@ReactModule(name = CaptureProtectionConstant.NAME)
class CaptureProtectionModule(private val reactContext: ReactApplicationContext) :
        ReactContextBaseJavaModule(reactContext), LifecycleEventListener {
  private val displayManager: DisplayManager =
          reactContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
  private val displayListener: DisplayManager.DisplayListener
  private val requestPermission =
          if (Build.VERSION.SDK_INT >= 33) "android.permission.READ_MEDIA_IMAGES"
          else Manifest.permission.READ_EXTERNAL_STORAGE
  private val screens = ArrayList<Int>()
  private var contentObserver: ContentObserver? = null

  companion object {
    var screenCaptureCallback: Any? = null
  }

  private fun getReactCurrentActivity(): Activity? {
    return reactContext.currentActivity
  }

  private fun getScreenCaptureCallback(): Method? {
    if (Build.VERSION.SDK_INT < 34) {
      return null
    }
    return Utils.getMethod(getReactCurrentActivity()!!.javaClass, "registerScreenCaptureCallback")
  }

  private fun createCaptureCallback() {
    if (Build.VERSION.SDK_INT < 34) {
      Log.d(CaptureProtectionConstant.NAME, "under Android 14 is not supported")
      return
    }
    if (screenCaptureCallback != null) {
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
                                        CaptureProtectionConstant.NAME,
                                        "=> capture onScreenCaptured add event "
                                )
                                val flags = isSecureFlag()
                                sendEvent(
                                        CaptureProtectionConstant.LISTENER_EVENT_NAME,
                                        flags,
                                        flags,
                                        CaptureProtectionConstant.CaptureProtectionModuleStatus
                                                .CAPTURE_DETECTED
                                                .ordinal
                                )
                              } catch (e: Exception) {
                                Log.e(
                                        CaptureProtectionConstant.NAME,
                                        "onScreenCaptured has raise Exception: " +
                                                e.localizedMessage
                                )
                              }
                              return@InvocationHandler null
                            }
                            m.invoke(proxy, *args)
                          }
                  )
          screenCaptureCallback = dynamic
          break
        }
      }
    } catch (e: Exception) {
      Log.e(
              CaptureProtectionConstant.NAME,
              "createCaptureCallback has raise Exception: " + e.localizedMessage
      )
    }
  }

  init {
    createCaptureCallback()
    displayListener =
            object : DisplayManager.DisplayListener {
              override fun onDisplayAdded(displayId: Int) {
                currentActivity?.runOnUiThread {
                  if (displayManager.getDisplay(displayId) == null) {
                    screens.add(displayId)
                  }
                  try {
                    val flags = isSecureFlag()
                    sendEvent(
                            CaptureProtectionConstant.LISTENER_EVENT_NAME,
                            flags,
                            flags,
                            if (screens.isEmpty())
                                    CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN
                                            .ordinal
                            else
                                    CaptureProtectionConstant.CaptureProtectionModuleStatus
                                            .RECORD_DETECTED_START
                                            .ordinal
                    )
                    Log.d(CaptureProtectionConstant.NAME, "=> display add event $displayId")
                  } catch (e: Exception) {
                    Log.e(
                            CaptureProtectionConstant.NAME,
                            "display add event Error with displayId: $displayId, error: ${e.message}"
                    )
                  }
                }
              }

              override fun onDisplayRemoved(displayId: Int) {
                currentActivity?.runOnUiThread {
                  val index = screens.indexOf(displayId)
                  if (index > -1) {
                    screens.removeAt(index)
                  }
                  try {
                    val flags = isSecureFlag()
                    sendEvent(
                            CaptureProtectionConstant.LISTENER_EVENT_NAME,
                            flags,
                            flags,
                            if (screens.isNotEmpty())
                                    CaptureProtectionConstant.CaptureProtectionModuleStatus
                                            .RECORD_DETECTED_START
                                            .ordinal
                            else
                                    CaptureProtectionConstant.CaptureProtectionModuleStatus
                                            .RECORD_DETECTED_END
                                            .ordinal
                    )
                    Log.d(CaptureProtectionConstant.NAME, "=> display remove event $displayId")
                  } catch (e: Exception) {
                    Log.e(
                            CaptureProtectionConstant.NAME,
                            "display remove event Error with displayId: $displayId, error: ${e.message}"
                    )
                  }
                }
              }

              override fun onDisplayChanged(displayId: Int) {
                Log.d(CaptureProtectionConstant.NAME, "=> display change event $displayId")
              }
            }
    displayManager.registerDisplayListener(displayListener, Utils.MainHandler)
    reactContext.addLifecycleEventListener(this)
  }

  override fun onHostResume() {
    try {
      val registerScreenCaptureCallback = getScreenCaptureCallback()
      if (registerScreenCaptureCallback != null) {
        if (screenCaptureCallback == null) {
          createCaptureCallback()
        }
        registerScreenCaptureCallback.invoke(
                getReactCurrentActivity(),
                Utils.MainExecutor,
                screenCaptureCallback
        )
      }
    } catch (e: Exception) {
      Log.e(
              CaptureProtectionConstant.NAME,
              "onHostResume has raise Exception: " + e.localizedMessage
      )
    }
  }

  override fun onHostPause() {}

  override fun onHostDestroy() {
    try {
      if (Build.VERSION.SDK_INT >= 34) {
        val method =
                Utils.getMethod(
                        getReactCurrentActivity()!!.javaClass,
                        "unregisterScreenCaptureCallback"
                )
        if (method != null && screenCaptureCallback != null) {
          method.invoke(getReactCurrentActivity(), screenCaptureCallback)
        }
      }
    } catch (e: Exception) {
      Log.e(
              CaptureProtectionConstant.NAME,
              "onHostDestroy has raise Exception: " + e.localizedMessage
      )
    }
  }

  private fun checkStoragePermission(): Boolean {
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
              CaptureProtectionConstant.NAME,
              "checkStoragePermission has raise Exception: " + e.localizedMessage
      )
      false
    }
  }

  private fun requestStoragePermission(): Boolean {
    return try {
      val isGranted = checkStoragePermission()
      if (getReactCurrentActivity() == null) {
        return false
      }
      if (isGranted) {
        Log.d(CaptureProtectionConstant.NAME, "Permission is granted")
        return true
      }
      Log.d(CaptureProtectionConstant.NAME, "Permission is revoked")
      ActivityCompat.requestPermissions(getReactCurrentActivity()!!, arrayOf(requestPermission), 1)
      false
    } catch (e: Exception) {
      Log.e(
              CaptureProtectionConstant.NAME,
              "requestStoragePermission has raise Exception: " + e.localizedMessage
      )
      false
    }
  }

  private fun addListener() {
    if (getScreenCaptureCallback() == null) {
      if (contentObserver == null && checkStoragePermission()) {
        contentObserver =
                object : ContentObserver(Utils.MainHandler) {
                  override fun onChange(selfChange: Boolean, uri: Uri?) {
                    if (uri != null &&
                                    uri.toString()
                                            .matches(
                                                    Regex(
                                                            MediaStore.Images.Media
                                                                    .EXTERNAL_CONTENT_URI
                                                                    .toString() + "/[0-9]+"
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
                                          cursor.getColumnIndex(MediaStore.Images.Media.DATA)
                                  )
                          if (path != null && path.toLowerCase().contains("screenshots")) {
                            Log.d(
                                    CaptureProtectionConstant.NAME,
                                    "contentObserver detect screenshot file$path"
                            )
                            val flags = isSecureFlag()
                            sendEvent(
                                    CaptureProtectionConstant.LISTENER_EVENT_NAME,
                                    flags,
                                    flags,
                                    CaptureProtectionConstant.CaptureProtectionModuleStatus
                                            .CAPTURE_DETECTED
                                            .ordinal
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
                contentObserver!!
        )
      }
    } else {
      if (screenCaptureCallback == null) {
        createCaptureCallback()
      }
    }
  }

  private fun removeListener() {
    contentObserver?.let { reactContext.contentResolver.unregisterContentObserver(it) }
  }

  private fun isSecureFlag(): Boolean {
    val currentActivity = getReactCurrentActivity()
    return currentActivity?.window?.attributes?.flags?.and(
            WindowManager.LayoutParams.FLAG_SECURE
    ) != 0
  }

  private fun sendEvent(eventName: String, params: WritableMap) {
    Log.d(CaptureProtectionConstant.NAME, "send event '$eventName' params: $params")
    reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(eventName, params)
  }

  private fun sendEvent(
          eventName: String,
          preventRecord: Boolean,
          preventScreenshot: Boolean,
          status: Int
  ) {
    val params = Arguments.createMap()
    params.putMap("isPrevent", Utils.createPreventStatusMap(preventScreenshot, preventRecord))
    params.putInt("status", status)
    sendEvent(eventName, params)
  }

  @NonNull
  override fun getName(): String {
    return CaptureProtectionConstant.NAME
  }

  @ReactMethod
  fun addListener(eventName: String) {
    addListener()
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    removeListener()
  }

  @ReactMethod
  fun addScreenshotListener() {
    addListener()
  }

  @ReactMethod
  fun removeScreenshotListener() {
    removeListener()
  }

  @ReactMethod
  fun hasListener(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val params =
                Utils.createPreventStatusMap(
                        contentObserver != null || getScreenCaptureCallback() != null,
                        displayListener != null
                )
        promise.resolve(params)
      } catch (e: Exception) {
        promise.reject("hasListener", e)
      }
    }
  }

  @ReactMethod
  fun isScreenRecording(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        promise.resolve(screens.size > 1)
      } catch (e: Exception) {
        promise.reject("preventScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun preventScreenshot(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val currentActivity = getReactCurrentActivity()
        if (currentActivity == null) {
          Log.w(CaptureProtectionConstant.NAME, "preventScreenshot: Current Activity is null")
        } else {
          currentActivity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
          sendEvent(
                  CaptureProtectionConstant.LISTENER_EVENT_NAME,
                  true,
                  true,
                  CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal
          )
          addListener()
          promise.resolve(true)
        }
      } catch (e: Exception) {
        promise.reject("preventScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun allowScreenshot(removeListener: Boolean, promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val currentActivity = getReactCurrentActivity()
        if (currentActivity == null) {
          Log.w(CaptureProtectionConstant.NAME, "allowScreenshot: Current Activity is null")
        } else {
          currentActivity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
          sendEvent(
                  CaptureProtectionConstant.LISTENER_EVENT_NAME,
                  false,
                  false,
                  CaptureProtectionConstant.CaptureProtectionModuleStatus.UNKNOWN.ordinal
          )
          if (removeListener) {
            removeListener()
          }
          promise.resolve(true)
        }
      } catch (e: Exception) {
        promise.reject("allowScreenshot", e)
      }
    }
  }

  @ReactMethod
  fun getPreventStatus(promise: Promise) {
    currentActivity?.runOnUiThread {
      try {
        val flags = isSecureFlag()
        val statusMap = Utils.createPreventStatusMap(flags, flags)
        promise.resolve(statusMap)
      } catch (e: Exception) {
        promise.reject("getPreventStatus", e)
      }
    }
  }

  @ReactMethod
  fun requestPermission(promise: Promise) {
    val isPermission = requestStoragePermission()
    promise.resolve(isPermission)
  }

  @ReactMethod
  fun checkPermission(promise: Promise) {
    val isPermission = checkStoragePermission()
    promise.resolve(isPermission)
  }
}
