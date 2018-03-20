package com.wix.RNCameraKit.camera.barcode;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.support.annotation.ColorInt;
import android.util.Log;
import android.view.View;

import com.wix.RNCameraKit.R;

public class BarcodeFrame extends View {

    private static final int STROKE_WITDH = 5;

    private Paint dimPaint;
    private Paint framePaint;
    private Paint borderPaint;
    private Paint laserPaint;
    private Rect frameRect;
    private int width;
    private int height;
    private int borderMargin;

    private long previousFrameTime = System.currentTimeMillis();
    private int laserY;

    public BarcodeFrame(Context context) {
        super(context);
        init(context);
    }

    private void init(Context context) {
        framePaint = new Paint();
        framePaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        dimPaint = new Paint();
        dimPaint.setStyle(Paint.Style.FILL);
        dimPaint.setColor(context.getResources().getColor(R.color.bg_dark));
        borderPaint = new Paint();
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setStrokeWidth(STROKE_WITDH);
        laserPaint = new Paint();
        laserPaint.setStyle(Paint.Style.STROKE);
        laserPaint.setStrokeWidth(STROKE_WITDH);

        frameRect = new Rect();
        borderMargin = context.getResources().getDimensionPixelSize(R.dimen.border_length);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        width = getMeasuredWidth();
        height = getMeasuredHeight();
        int marginWidth = width / 7;
        int marginHeight = (int) (height / 2.75);

        frameRect.left = marginWidth;
        frameRect.right = width - marginWidth;
        frameRect.top = marginHeight;
        frameRect.bottom = height - marginHeight;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        long timeElapsed = (System.currentTimeMillis() - previousFrameTime);
        super.onDraw(canvas);
        canvas.drawRect(0, 0, width, height, dimPaint);
        canvas.drawRect(frameRect, framePaint);
        drawBorder(canvas);
        drawLaser(canvas, timeElapsed);
        previousFrameTime = System.currentTimeMillis();
        this.invalidate(frameRect);
    }

    private void drawBorder(Canvas canvas) {
        canvas.drawLine(frameRect.left, frameRect.top, frameRect.left, frameRect.top + borderMargin, borderPaint);
        canvas.drawLine(frameRect.left, frameRect.top, frameRect.left + borderMargin, frameRect.top, borderPaint);
        canvas.drawLine(frameRect.left, frameRect.bottom, frameRect.left, frameRect.bottom - borderMargin, borderPaint);
        canvas.drawLine(frameRect.left, frameRect.bottom, frameRect.left + borderMargin, frameRect.bottom, borderPaint);
        canvas.drawLine(frameRect.right, frameRect.top, frameRect.right - borderMargin, frameRect.top, borderPaint);
        canvas.drawLine(frameRect.right, frameRect.top, frameRect.right, frameRect.top + borderMargin, borderPaint);
        canvas.drawLine(frameRect.right, frameRect.bottom, frameRect.right, frameRect.bottom - borderMargin, borderPaint);
        canvas.drawLine(frameRect.right, frameRect.bottom, frameRect.right - borderMargin, frameRect.bottom, borderPaint);
    }

    private void drawLaser(Canvas canvas, long timeElapsed) {
        if (laserY > frameRect.bottom || laserY < frameRect.top) laserY = frameRect.top;
        canvas.drawLine(frameRect.left + STROKE_WITDH, laserY, frameRect.right - STROKE_WITDH, laserY, laserPaint);
        laserY += (timeElapsed) / 8;
    }

    public Rect getFrameRect() {
        return frameRect;
    }

    public void setFrameColor(@ColorInt int borderColor) {
        borderPaint.setColor(borderColor);
    }

    public void setLaserColor(@ColorInt int laserColor) {
        laserPaint.setColor(laserColor);
    }
}
