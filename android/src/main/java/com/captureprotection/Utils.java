package com.captureprotection;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;

import java.lang.reflect.Method;
import java.util.concurrent.Executor;

public class Utils {
    private final static String NAME = CaptureProtectionConstant.NAME + "_Utils";

    public static final class MainExecutor implements Executor {
        static final Executor INSTANCE = new MainExecutor();
        private final Handler handler = new Handler(Looper.getMainLooper());

        @Override
        public void execute(Runnable r) {
            handler.post(r);
        }
    }

    public static final class MainHandler {
        static final Handler INSTANCE = new Handler(Looper.getMainLooper(), new Handler.Callback() {
            @Override
            public boolean handleMessage(@NonNull Message msg) {
                return false;
            }
        });
    }

    public static Method getMethod(Class<?> c, String name) {
        try {
            while (c != null) {
                for (Method method : c.getDeclaredMethods()) {
                    if (method.getName().equals(name)) {
                        Log.d(NAME, "getMethod has find function name: " + name);
                        return method;
                    }
                }
                c = c.getSuperclass();
            }
            return null;
        } catch (Exception e) {
            Log.e(NAME, "getMethod has raise Exception: " + e.getLocalizedMessage());
            return null;
        }
    }

    public static WritableMap createPreventStatusMap(boolean screenshot, boolean recordScreen) {
        WritableMap statusMap = Arguments.createMap();
        statusMap.putBoolean("screenshot", screenshot);
        statusMap.putBoolean("record", recordScreen);
        return statusMap;
    }
}
