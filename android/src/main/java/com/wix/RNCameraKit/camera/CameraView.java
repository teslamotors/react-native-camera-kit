package com.wix.RNCameraKit.camera;

import android.graphics.Color;
import android.graphics.Rect;
import android.hardware.Camera;
import android.support.annotation.ColorInt;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;

import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.Utils;
import com.wix.RNCameraKit.camera.barcode.BarcodeFrame;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

public class CameraView extends FrameLayout implements SurfaceHolder.Callback {
    private ThemedReactContext context;
    private SurfaceView surface;

    private Rect frameRect;
    private BarcodeFrame barcodeFrame;
    @ColorInt private int frameColor = Color.GREEN;
    @ColorInt private int laserColor = Color.RED;

    public CameraView(ThemedReactContext context) {
        super(context);
        this.context = context;


        surface = new SurfaceView(context);
        setBackgroundColor(Color.BLACK);
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
        int height = Utils.convertDeviceHeightToSupportedAspectRatio(actualPreviewWidth, actualPreviewHeight);
        surface.layout(0, 0, actualPreviewWidth, height);
        if (barcodeFrame != null) {
            ((View) barcodeFrame).layout(0, 0, actualPreviewWidth, height);
        }
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

    private final Runnable measureAndLayout = new Runnable() {
        @Override
        public void run() {
            measure(
                    MeasureSpec.makeMeasureSpec(getWidth(), MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(getHeight(), MeasureSpec.EXACTLY));
            layout(getLeft(), getTop(), getRight(), getBottom());
        }
    };

    @Override
    public void requestLayout() {
        super.requestLayout();
        post(measureAndLayout);
    }

    public void showFrame() {
        barcodeFrame = new BarcodeFrame(getContext());
        barcodeFrame.setFrameColor(frameColor);
        barcodeFrame.setLaserColor(laserColor);
        addView(barcodeFrame);
        requestLayout();
    }

    public Rect getFramingRectInPreview(int previewWidth, int previewHeight) {
        if (frameRect == null) {
            if (barcodeFrame != null) {
                Rect framingRect = barcodeFrame.getFrameRect();
                int viewFinderViewWidth = barcodeFrame.getWidth();
                int viewFinderViewHeight = barcodeFrame.getHeight();
                if (framingRect == null || viewFinderViewWidth == 0 || viewFinderViewHeight == 0) {
                    return null;
                }

                Rect rect = new Rect(framingRect);

                if (previewWidth < viewFinderViewWidth) {
                    rect.left = rect.left * previewWidth / viewFinderViewWidth;
                    rect.right = rect.right * previewWidth / viewFinderViewWidth;
                }

                if (previewHeight < viewFinderViewHeight) {
                    rect.top = rect.top * previewHeight / viewFinderViewHeight;
                    rect.bottom = rect.bottom * previewHeight / viewFinderViewHeight;
                }

                frameRect = rect;

            } else {
                frameRect = new Rect(0, 0, previewWidth, previewHeight);
            }
        }
        return frameRect;
    }

    public void setFrameColor(@ColorInt int color) {
        this.frameColor = color;
        if (barcodeFrame != null) {
            barcodeFrame.setFrameColor(color);
        }
    }

    public void setLaserColor(@ColorInt int color) {
        this.laserColor = color;
        if (barcodeFrame != null) {
            barcodeFrame.setLaserColor(laserColor);
        }
    }
}
