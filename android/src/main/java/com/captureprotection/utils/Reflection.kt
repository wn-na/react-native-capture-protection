package com.captureprotection

import android.util.Log
import com.captureprotection.constants.Constants
import java.lang.reflect.Method

class Reflection() {
    companion object {
        private val NAME = "${Constants.NAME}_Reflection"
        fun getMethod(c: Class<*>?, name: String): Method? {
            return try {
                generateSequence(c) { it.superclass }
                        .flatMap { it.declaredMethods.asSequence() }
                        .firstOrNull { it.name == name }
                        ?.apply { Log.d(NAME, "found function: $name") }
            } catch (e: Exception) {
                Log.e(NAME, "Exception: ${e.localizedMessage}")
                null
            }
        }
    }
}
