package com.wix.RNCameraKit.camera;

import android.app.Activity;
import android.hardware.Camera;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.Toast;

import com.facebook.react.uimanager.ThemedReactContext;

import java.io.IOException;
import java.util.List;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraView extends SurfaceView implements SurfaceHolder.Callback {

    private ThemedReactContext context;
    private Camera camera;
    private String flashMode = Camera.Parameters.FLASH_MODE_AUTO;

    public static CameraView instance;
    private int currentCamera = 0;
    private Camera.Size optimalSize;
    private Camera.Size optimalPictureSize;

    public CameraView(ThemedReactContext context) {
        super(context);

        if (instance != null) {
            instance.unlock();
        }

        instance = this;
        this.context = context;

        this.getHolder().addCallback(this);
        this.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (camera != null) {
                    CameraView.this.camera.autoFocus(new Camera.AutoFocusCallback() {
                        @Override
                        public void onAutoFocus(boolean success, Camera camera) {}
                    });
                }
            }
        });
    }

    public void unlock() {
        if (camera != null) {
            camera.unlock();
        }
    }

    public boolean changeCamera() {
        if (Camera.getNumberOfCameras() == 1) {
            return false;
        }
        currentCamera++;
        currentCamera = currentCamera % Camera.getNumberOfCameras();
        camera.release();
        initCamera();
        return true;
    }

    private void initCamera() {
        try {
            this.camera = Camera.open(currentCamera);
            camera.setPreviewDisplay(this.getHolder());
            updateCameraSize();
            camera.startPreview();
            setCameraDisplayOrientation(((Activity)context.getBaseContext()), 0, camera);
        } catch (IOException e) {
        } catch (RuntimeException e) {
            Toast.makeText(getContext(), "Cannot connect to Camera", Toast.LENGTH_SHORT).show();
        }
    }

    private void updateCameraSize() {
        if (camera == null) return;
        List<Camera.Size> supportedPreviewSizes = camera.getParameters().getSupportedPreviewSizes();
        List<Camera.Size> supportedPictureSizes = camera.getParameters().getSupportedPictureSizes();
        optimalSize = getOptimalPreviewSize(supportedPreviewSizes, getWidth(), getHeight());
        optimalPictureSize = getOptimalPreviewSize(supportedPictureSizes, getWidth(), getHeight());
        Camera.Parameters parameters = camera.getParameters();
        parameters.setPreviewSize(optimalSize.width, optimalSize.height);
        parameters.setPictureSize(optimalPictureSize.width, optimalPictureSize.height);
        parameters.setFlashMode(flashMode);
        camera.setParameters(parameters);
        camera.startPreview();
    }

    public static void setCameraDisplayOrientation(Activity activity, int cameraId, android.hardware.Camera camera) {
        android.hardware.Camera.CameraInfo info =
                new android.hardware.Camera.CameraInfo();
        android.hardware.Camera.getCameraInfo(cameraId, info);
        int rotation = activity.getWindowManager().getDefaultDisplay()
                .getRotation();
        int degrees = 0;
        switch (rotation) {
            case Surface.ROTATION_0:
                degrees = 0;
                break;
            case Surface.ROTATION_90:
                degrees = 90;
                break;
            case Surface.ROTATION_180:
                degrees = 180;
                break;
            case Surface.ROTATION_270:
                degrees = 270;
                break;
        }

        int result;
        if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            result = (info.orientation + degrees) % 360;
            result = (360 - result) % 360;  // compensate the mirror
        } else {  // back-facing
            result = (info.orientation - degrees + 360) % 360;
        }
        camera.setDisplayOrientation(result);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        initCamera();
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        updateCameraSize();
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        if (camera != null) {
            camera.release();
        }
    }

    public Camera getCamera() {
        return camera;
    }

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

    public boolean setFlashMode(String mode) {
        if (camera == null) {
            return false;
        }
        Camera.Parameters parameters = camera.getParameters();
        if(parameters.getSupportedFlashModes().contains(mode)) {
            flashMode = mode;
            parameters.setFlashMode(flashMode);
            camera.setParameters(parameters);
            camera.startPreview();
            return true;
        } else {
            return false;
        }
    }
}
