package com.captureprotection

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import java.lang.reflect.Method
import java.util.concurrent.Executor

class Utils() {
    object MainExecutor : Executor {
        private val handler = Handler(Looper.getMainLooper())

        override fun execute(r: Runnable) {
            handler.post(r)
        }
    }

    object MainHandler : Handler(Looper.getMainLooper(), Callback { false })

    companion object {
        private val NAME = "${CaptureProtectionConstant.NAME}_Utils"
        fun getMethod(c: Class<*>?, name: String): Method? {
            return try {
                generateSequence(c) { it.superclass }
                        .flatMap { it.declaredMethods.asSequence() }
                        .firstOrNull { it.name == name }
                        ?.apply { Log.d(NAME, "getMethod has found function name: $name") }
            } catch (e: Exception) {
                Log.e(NAME, "getMethod has raised an Exception: ${e.localizedMessage}")
                null
            }
        }

        fun createPreventStatusMap(screenshot: Boolean, recordScreen: Boolean): WritableMap {
            return Arguments.createMap().apply {
                putBoolean("screenshot", screenshot)
                putBoolean("record", recordScreen)
            }
        }
    }
}
