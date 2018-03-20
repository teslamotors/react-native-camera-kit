package com.wix.RNCameraKit.camera.barcode;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.Rect;
import android.util.Log;
import android.view.View;

import com.wix.RNCameraKit.R;

public class BarcodeFrame extends View {

    private Paint dimPaint;
    private Paint framePaint;
    private Rect frameRect;
    private int width;
    private int height;

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

        frameRect = new Rect();
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);

        width = getMeasuredWidth();
        height = getMeasuredHeight();
        int marginWidth = width / 3;
        int marginHeight = height / 3;

        frameRect.left = marginWidth;
        frameRect.right = width - marginWidth;
        frameRect.top = marginHeight;
        frameRect.bottom = height - marginHeight;
        Log.i("NIGA", String.format("w=%d, h=%d ", width, height) + frameRect.toShortString());
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        canvas.drawRect(0, 0, width, height, dimPaint);
        canvas.drawRect(frameRect, framePaint);
    }

    public Rect getFrameRect() {
        return frameRect;
    }
}
