package com.rncamerakit.gallery;

/**
 * Created by yedidyak on 18/07/2016.
 */
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.StrictMode;

import com.facebook.common.util.UriUtil;

import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import javax.annotation.Nullable;

/**
 * Helper class for obtaining information about local images.
 */
public class ResourceDrawableIdHelper {

    private Map<String, Integer> mResourceDrawableIdMap;

    public ResourceDrawableIdHelper() {
        mResourceDrawableIdMap = new HashMap<>();
    }

    public int getResourceDrawableId(Context context, @Nullable String name) {
        if (name == null || name.isEmpty()) {
            return 0;
        }
        name = name.toLowerCase().replace("-", "_");
        if (mResourceDrawableIdMap.containsKey(name)) {
            return mResourceDrawableIdMap.get(name);
        }
        int id = context.getResources().getIdentifier(
                name,
                "drawable",
                context.getPackageName());
        mResourceDrawableIdMap.put(name, id);
        return id;
    }

    @Nullable
    public Drawable getResourceDrawable(Context context, @Nullable String name) {
        int resId = getResourceDrawableId(context, name);
        return resId > 0 ? context.getResources().getDrawable(resId) : null;
    }

    public Uri getResourceDrawableUri(Context context, @Nullable String name) {
        int resId = getResourceDrawableId(context, name);
        return resId > 0 ? new Uri.Builder()
                .scheme(UriUtil.LOCAL_RESOURCE_SCHEME)
                .path(String.valueOf(resId))
                .build() : Uri.EMPTY;
    }

    public static final String LOCAL_RESOURCE_URI_SCHEME = "res";
    private static ResourceDrawableIdHelper sResDrawableIdHelper = new ResourceDrawableIdHelper();

    public static Drawable getIcon(Context ctx, String iconSource) {
        return getIcon(ctx, iconSource, -1);
    }

    /**
     * @param iconSource Icon source. In release builds this would be a path in assets, In debug it's
     *                   a url and the image needs to be decoded from input stream.
     * @param dimensions The requested icon dimensions
     */
    public static Drawable getIcon(Context ctx, String iconSource, int dimensions) {
        if (iconSource == null) {
            return null;
        }

        try {
            Drawable icon;
            Uri iconUri = getIconUri(ctx, iconSource);

            if (LOCAL_RESOURCE_URI_SCHEME.equals(iconUri.getScheme())) {
                icon = sResDrawableIdHelper.getResourceDrawable(ctx, iconSource);
            } else {
                URL url = new URL(iconUri.toString());

                StrictMode.ThreadPolicy oldPolicy = StrictMode.getThreadPolicy();
                StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
                StrictMode.setThreadPolicy(policy);
                Bitmap bitmap = BitmapFactory.decodeStream(url.openStream());
                StrictMode.setThreadPolicy(oldPolicy);
                bitmap = dimensions > 0 ?
                        Bitmap.createScaledBitmap(bitmap, dimensions, dimensions, false) : bitmap;
                icon = new BitmapDrawable(ctx.getResources(), bitmap);
            }
            return icon;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static Uri getIconUri(Context context, String iconSource) {
        Uri ret = null;
        if (iconSource != null) {
            try {
                ret = Uri.parse(iconSource);
                // Verify scheme is set, so that relative uri (used by static resources) are not handled.
                if (ret.getScheme() == null) {
                    ret = null;
                }
            } catch (Exception e) {
                // Ignore malformed uri, then attempt to extract resource ID.
            }
            if (ret == null) {
                ret = sResDrawableIdHelper.getResourceDrawableUri(context, iconSource);
            }
        }
        return ret;
    }
}