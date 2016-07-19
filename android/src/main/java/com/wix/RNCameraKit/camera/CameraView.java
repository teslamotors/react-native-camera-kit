package com.wix.RNCameraKit.camera;

import android.hardware.Camera;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;

import com.facebook.react.uimanager.ThemedReactContext;

import java.util.List;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraView extends SurfaceView implements SurfaceHolder.Callback {

    private ThemedReactContext context;

    public CameraView(ThemedReactContext context) {
        super(context);
        this.context = context;
        this.getHolder().addCallback(this);
        this.setOnClickListener(new OnClickListener() {
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
    public void surfaceCreated(SurfaceHolder holder) {
        CameraViewManager.setCameraView(this);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        CameraViewManager.updateCameraSize();
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {}



}
