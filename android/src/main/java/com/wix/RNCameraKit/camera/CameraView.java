package com.wix.RNCameraKit.camera;

import android.hardware.Camera;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;

import com.facebook.react.uimanager.ThemedReactContext;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraView extends FrameLayout implements SurfaceHolder.Callback {

    private ThemedReactContext context;
    private SurfaceView surface;

    public CameraView(ThemedReactContext context) {
        super(context);
        this.context = context;

        this.surface = new SurfaceView(context);
        addView(surface, MATCH_PARENT, MATCH_PARENT);
        surface.getHolder().addCallback(this);
        surface.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (CameraViewManager.getCamera() != null) {
                    try {
                        CameraViewManager.getCamera().autoFocus(new Camera.AutoFocusCallback() {
                            @Override
                            public void onAutoFocus(boolean success, Camera camera) {
                            }
                        });
                    } catch (Exception e) {

                    }
                }
            }
        });
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        int actualPreviewWidth = getResources().getDisplayMetrics().widthPixels;
        int actualPreviewHeight = getResources().getDisplayMetrics().heightPixels;
        surface.layout(0, 0, actualPreviewWidth, actualPreviewHeight);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        CameraViewManager.setCameraView(this);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        CameraViewManager.removeCameraView();


    public SurfaceHolder getHolder() {
        return surface.getHolder();
    }
}
