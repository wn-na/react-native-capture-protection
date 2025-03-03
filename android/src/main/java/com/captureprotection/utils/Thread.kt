package com.captureprotection.utils

import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executor

class ModuleThread {
    companion object {
        val MainHandler = Handler(Looper.getMainLooper())
        val MainExecutor = Executor { command -> MainHandler.post(command) }
    }
}
