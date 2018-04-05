package com.wix.RNCameraKit.camera.barcode;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.view.View;

import com.facebook.react.bridge.ReadableMap;
import com.wix.RNCameraKit.R;
import com.wix.RNCameraKit.Utils;

public class BarcodeFrame extends View {

    private static final int STROKE_WIDTH = 5;
    private static final int ANIMATION_SPEED = 8;

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

    public BarcodeFrame(Context context, ReadableMap options) {
        super(context);
        init(context, options);
    }

    private void init(Context context, ReadableMap options) {
        framePaint = new Paint();
        framePaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));
        dimPaint = new Paint();
        dimPaint.setStyle(Paint.Style.FILL);
        dimPaint.setColor(context.getResources().getColor(R.color.bg_dark));
        borderPaint = new Paint();
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setStrokeWidth(STROKE_WIDTH);
        laserPaint = new Paint();
        laserPaint.setStyle(Paint.Style.STROKE);
        laserPaint.setStrokeWidth(STROKE_WIDTH);

        frameRect = new Rect();
        borderMargin = context.getResources().getDimensionPixelSize(R.dimen.border_length);
        parseOptions(options);
    }

    private void parseOptions(ReadableMap options) {
        frameRect.left = Utils.convertDpToPx(Utils.getIntSafe(options, "frameLeft", 0), getContext());
        frameRect.top = Utils.convertDpToPx(Utils.getIntSafe(options, "frameTop", 0), getContext());
        frameRect.right = frameRect.left + Utils.convertDpToPx(Utils.getIntSafe(options, "frameWidth", 0), getContext());
        frameRect.bottom = frameRect.top + Utils.convertDpToPx(Utils.getIntSafe(options, "frameHeight", 0), getContext());
        borderPaint.setColor(Utils.getIntSafe(options, "frameColor", Color.GREEN));
        laserPaint.setColor(Utils.getIntSafe(options, "laserColor", Color.RED));
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        width = getMeasuredWidth();
        height = getMeasuredHeight();
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
        canvas.drawLine(frameRect.left + STROKE_WIDTH, laserY, frameRect.right - STROKE_WIDTH, laserY, laserPaint);
        laserY += (timeElapsed) / ANIMATION_SPEED;
    }

    public Rect getFrameRect() {
        return frameRect;
    }

}
