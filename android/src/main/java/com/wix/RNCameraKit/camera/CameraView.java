package com.wix.RNCameraKit.camera;

import android.graphics.Color;
import android.graphics.Rect;
import android.support.annotation.ColorInt;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.FrameLayout;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.wix.RNCameraKit.Utils;
import com.wix.RNCameraKit.camera.barcode.BarcodeFrame;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;

public class CameraView extends FrameLayout implements SurfaceHolder.Callback {
    private SurfaceView surface;

    private boolean showFrame;
    private Rect frameRect;
    private BarcodeFrame barcodeFrame;
    private ReadableMap scannerOptions;

    public CameraView(ThemedReactContext context) {
        super(context);
        surface = new SurfaceView(context);
        setBackgroundColor(Color.BLACK);
        addView(surface, MATCH_PARENT, MATCH_PARENT);
        surface.getHolder().addCallback(this);
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

    public void setShowFrame(boolean showFrame) {
        this.showFrame = showFrame;
    }

    public void showFrame() {
        if (showFrame) {
            barcodeFrame = new BarcodeFrame(getContext(), scannerOptions);
            addView(barcodeFrame);
            requestLayout();
        }
    }

    public Rect getFramingRectInPreview(int previewWidth, int previewHeight) {
        if (frameRect == null) {
            if (barcodeFrame != null) {
                Rect framingRect = new Rect(barcodeFrame.getFrameRect());
                int frameWidth = barcodeFrame.getWidth();
                int frameHeight = barcodeFrame.getHeight();

                if (previewWidth < frameWidth) {
                    framingRect.left = framingRect.left * previewWidth / frameWidth;
                    framingRect.right = framingRect.right * previewWidth / frameWidth;
                }
                if (previewHeight < frameHeight) {
                    framingRect.top = framingRect.top * previewHeight / frameHeight;
                    framingRect.bottom = framingRect.bottom * previewHeight / frameHeight;
                }

                frameRect = framingRect;
            } else {
                frameRect = new Rect(0, 0, previewWidth, previewHeight);
            }
        }
        return frameRect;
    }

    /**
     * Set background color for Surface view on the period, while camera is not loaded yet.
     * Provides opportunity for user to hide period while camera is loading
     *
     * @param color - color of the surfaceview
     */
    public void setSurfaceBgColor(@ColorInt int color) {
        surface.setBackgroundColor(color);
    }

    public void setScannerOptions(ReadableMap scannerOptions) {
        this.scannerOptions = scannerOptions;
    }
}
