package com.captureprotection

import android.app.Activity
import android.util.Log
import com.captureprotection.constants.Constants
import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy

class Reflection {
    companion object {
        private val NAME = "${Constants.NAME}_Reflection"
        fun getMethod(c: Class<*>?, methodName: String): Method? {
            return try {
                generateSequence(c) { it.superclass }
                        .flatMap { it.declaredMethods.asSequence() }
                        .firstOrNull { it.name == methodName }
            } catch (e: Exception) {
                Log.e(NAME, "Exception: ${methodName} -> ${e.localizedMessage}")
                null
            }
        }

        fun createScreenCaptureCallback(onCapturedAction: () -> Unit): Any? {
            val declaredClasses = Activity::class.java.declaredClasses
            if (declaredClasses.isNullOrEmpty()) {
                Log.e(Constants.NAME, "No declared classes found in Activity.")
                return null
            }

            val clazz = declaredClasses.find { it.simpleName == "ScreenCaptureCallback" }
            if (clazz == null || !clazz.isInterface) {
                Log.e(
                        Constants.NAME,
                        "ScreenCaptureCallback interface not found or is not an interface."
                )
                return null
            }

            return Proxy.newProxyInstance(
                    clazz.classLoader,
                    arrayOf(clazz),
                    InvocationHandler { proxy, method, args ->
                        if (method.name == "onScreenCaptured") {
                            try {
                                Log.d(Constants.NAME, "=> capture onScreenCaptured add event")
                                onCapturedAction()
                            } catch (e: Exception) {
                                Log.e(
                                        Constants.NAME,
                                        "onScreenCaptured has raised Exception: ${e.localizedMessage}"
                                )
                            }
                            return@InvocationHandler null
                        }

                        when (method.returnType) {
                            Boolean::class.javaPrimitiveType -> return@InvocationHandler false
                            Int::class.javaPrimitiveType -> return@InvocationHandler 0
                            Float::class.javaPrimitiveType -> return@InvocationHandler 0.0f
                            Double::class.javaPrimitiveType -> return@InvocationHandler 0.0
                            Long::class.javaPrimitiveType -> return@InvocationHandler 0L
                            Short::class.javaPrimitiveType -> return@InvocationHandler 0.toShort()
                            Byte::class.javaPrimitiveType -> return@InvocationHandler 0.toByte()
                            Char::class.javaPrimitiveType -> return@InvocationHandler '\u0000'
                            else -> return@InvocationHandler null
                        }
                    }
            )
        }
    }
}
