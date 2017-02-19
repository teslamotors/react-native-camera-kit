package com.wix.RNCameraKit;

import android.content.Context;
import android.content.SharedPreferences;

// We're saving in shared preferences if a permission was requested since for some unknown reason,
// activitycompat.shouldshowrequestpermissionrationale always returned false
public class SharedPrefs {
    public static boolean getBoolean(Context context, String key) {
        return prefs(context).getBoolean(key, false);
    }

    public static void putBoolean(Context context, String key, boolean value) {
        prefs(context).edit().putBoolean(key, value).apply();
    }

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences("MEDIA_MANAGER", Context.MODE_PRIVATE);
    }


}
