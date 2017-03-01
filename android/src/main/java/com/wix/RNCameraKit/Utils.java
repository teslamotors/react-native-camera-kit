package com.wix.RNCameraKit;

import android.graphics.Bitmap;
import android.support.annotation.NonNull;
import android.util.Base64;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;

import javax.annotation.Nullable;

public class Utils {
    public static String getBase64FromBitmap(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream .toByteArray();
        return Base64.encodeToString(byteArray, Base64.DEFAULT);
    }

    @Nullable
    public static String getStringSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getString(key);
        }
        return null;
    }

    public static @Nullable Integer getIntSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getInt(key);
        }
        return null;
    }

    public static @Nullable Boolean getBooleanSafe(ReadableMap map, String key) {
        if (map.hasKey(key)) {
            return map.getBoolean(key);
        }
        return null;
    }

    public static @NonNull ArrayList<String> readableArrayToList(ReadableArray items) {
        ArrayList<String> list = new ArrayList<>();
        for(int i = 0; i < items.size(); i++) {
            list.add(items.getString(i));
        }
        return list;
    }
}
