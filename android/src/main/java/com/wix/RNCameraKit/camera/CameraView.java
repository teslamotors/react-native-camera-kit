package com.wix.RNCameraKit.camera;

import android.content.Context;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.LayoutInflater;

import com.wix.RNCameraKit.R;

public class CameraView extends com.wonderkiln.camerakit.CameraView {
    // When creating the view programmatically, it would crash when saving the image
    public static CameraView inflate(Context context) {
        return (CameraView) LayoutInflater.from(context).inflate(R.layout.camera_view, null);
    }

    public CameraView(@NonNull Context context) {
        super(context);
    }

    public CameraView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public void ensureToggleOnPreMarshmallow() {
        postInvalidateDelayed(500);
        postInvalidateDelayed(1000);
    }
}
