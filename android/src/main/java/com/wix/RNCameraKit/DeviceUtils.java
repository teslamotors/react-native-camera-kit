package com.wix.RNCameraKit;

import android.os.Build;

public class DeviceUtils {
    public static boolean isGoogleDevice() {
        return (Build.MANUFACTURER.toLowerCase().contains("google") && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) ||
               (Build.MANUFACTURER.toLowerCase().contains("lge") && Build.BRAND.toLowerCase().equals("google"));
    }
}
