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
                    CameraViewManager.getCamera().autoFocus(new Camera.AutoFocusCallback() {
                        @Override
                        public void onAutoFocus(boolean success, Camera camera) {}
                    });
                }
            }
        });
    }

    private void updateCameraSize() {
        try {
            Camera camera = CameraViewManager.getCamera();
            if (camera == null) return;
            List<Camera.Size> supportedPreviewSizes = camera.getParameters().getSupportedPreviewSizes();
            List<Camera.Size> supportedPictureSizes = camera.getParameters().getSupportedPictureSizes();
            Camera.Size optimalSize = getOptimalPreviewSize(supportedPreviewSizes, getWidth(), getHeight());
            Camera.Size optimalPictureSize = getOptimalPreviewSize(supportedPictureSizes, getWidth(), getHeight());
            Camera.Parameters parameters = camera.getParameters();
            parameters.setPreviewSize(optimalSize.width, optimalSize.height);
            parameters.setPictureSize(optimalPictureSize.width, optimalPictureSize.height);
            parameters.setFlashMode(CameraViewManager.getFlashMode());
            camera.setParameters(parameters);
            camera.startPreview();
        } catch (RuntimeException e) {
            CameraViewManager.initCamera();
            CameraViewManager.setHolder(getHolder());
            updateCameraSize();
        }
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        CameraViewManager.setHolder(holder);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        updateCameraSize();
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {}


    private static Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio=(double)h / w;
        if (sizes == null) return null;
        Camera.Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;
        int targetHeight = h;
        for (Camera.Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - targetHeight) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - targetHeight);
            }
        }
        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Camera.Size size : sizes) {
                if (Math.abs(size.height - targetHeight) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - targetHeight);
                }
            }
        }
        return optimalSize;
    }
}
