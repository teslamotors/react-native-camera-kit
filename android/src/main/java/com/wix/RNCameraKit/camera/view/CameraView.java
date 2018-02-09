package com.wix.RNCameraKit.camera.view;

import android.graphics.Color;
import android.hardware.Camera;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;

import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.Utils;
import com.wix.RNCameraKit.camera.CameraViewManager;

import java.util.List;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

public class CameraView extends FrameLayout implements SurfaceHolder.Callback {
    private ThemedReactContext context;
    private SurfaceView surface;
    private FocusView focusView;
    private boolean mIsAutoFocusing = false;

    public CameraView(final ThemedReactContext context) {
        super(context);
        this.context = context;

        setBackgroundColor(Color.BLACK);
        surface = new SurfaceView(context);
        focusView = new FocusView(context);
        addView(surface, MATCH_PARENT, MATCH_PARENT);
        addView(focusView, MATCH_PARENT, MATCH_PARENT);
        initView();
    }

    private void initView() {
        surface.getHolder().addCallback(this);
        focusView.setCameAreasUpdateListener(new CameraAreasUpdateListener() {

            @Override
            public void onCameraAreasUpdated(List<Camera.Area> areas) {
                CameraViewManager.setFocusingAreas(areas);
            }
        });
        surface.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (CameraViewManager.getCamera() == null || mIsAutoFocusing) {
                    return;
                }
                try {
                    mIsAutoFocusing = true;
                    CameraViewManager.getCamera().cancelAutoFocus();
                    boolean focusModeSetResult = CameraViewManager.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
                    if (focusModeSetResult) {
                        CameraViewManager.getCamera().autoFocus(new Camera.AutoFocusCallback() {
                            @Override
                            public void onAutoFocus(boolean success, Camera camera) {
                                mIsAutoFocusing = false;
                            }
                        });
                    } else {
                        mIsAutoFocusing = false;
                    }
                } catch (Exception ignored) {
                }
            }
        });
    }

    @Override
    protected void onLayout(boolean changed, int left, int top, int right, int bottom) {
        int actualPreviewWidth = getResources().getDisplayMetrics().widthPixels;
        int actualPreviewHeight = getResources().getDisplayMetrics().heightPixels;
        int height = Utils.convertDeviceHeightToSupportedAspectRatio(actualPreviewWidth, actualPreviewHeight);
        surface.layout(0, 0, actualPreviewWidth, height);
        focusView.layout(0, 0, actualPreviewHeight, height);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        CameraViewManager.setCameraView(this);
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        CameraViewManager.setCameraView(this);
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        CameraViewManager.removeCameraView();
    }


    public SurfaceHolder getHolder() {
        return surface.getHolder();
    }
}
