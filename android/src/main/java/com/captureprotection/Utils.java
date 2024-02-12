package com.captureprotection;

import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import androidx.annotation.NonNull;
import java.util.concurrent.Executor;

public class Utils {
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
}
