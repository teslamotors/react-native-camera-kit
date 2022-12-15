package com.rncamerakit.barcode

import android.content.Context
import android.graphics.*
import android.graphics.drawable.Drawable
import android.view.View
import androidx.annotation.ColorInt
import com.rncamerakit.R

class BarcodeFrame(context: Context) : View(context) {
    private var borderPaint: Paint = Paint()
    private var laserPaint: Paint = Paint()
    private var overlayPaint: Paint = Paint()
    private var previousFrameTime = System.currentTimeMillis()
    private var laserY = 0

    private var mDefaultFrame = RectF()
    private var mRectFrame = Rect()
    private var mCanvas = Canvas()
    private var mDrawable: Drawable? = null;
    
    private fun init(context: Context) {
        borderPaint = Paint()
        borderPaint.style = Paint.Style.STROKE
        borderPaint.strokeWidth = STROKE_WIDTH.toFloat()
        laserPaint.style = Paint.Style.STROKE
        laserPaint.strokeWidth = STROKE_WIDTH.toFloat()
        overlayPaint = Paint()
        overlayPaint.color = Color.parseColor("#80000000")
        mDrawable =  resources.getDrawable(R.drawable.qr_scanner, null)

    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val centerX = width / 2f

        val centerY = (height / 2f) - (RECTANGLE_HEIGHT / 2) - 50 

        mDefaultFrame.left = centerX - RECTANGLE_WIDTH
        mDefaultFrame.top = centerY - RECTANGLE_HEIGHT
        mDefaultFrame.right = centerX + RECTANGLE_WIDTH
        mDefaultFrame.bottom = centerY + RECTANGLE_HEIGHT

        mRectFrame.left = (centerX - RECTANGLE_WIDTH).toInt()
        mRectFrame.top = (centerY - RECTANGLE_HEIGHT).toInt()
        mRectFrame.right = (centerX + RECTANGLE_WIDTH).toInt()
        mRectFrame.bottom = (centerY + RECTANGLE_HEIGHT).toInt()
    }

    override fun onDraw(canvas: Canvas) {
        val timeElapsed = System.currentTimeMillis() - previousFrameTime
        super.onDraw(canvas)
        mCanvas = canvas
        drawLaser(canvas, timeElapsed)
        drawOverlay(canvas)
        drawBorder(canvas)
        previousFrameTime = System.currentTimeMillis()
        invalidate()
    }

    private fun drawOverlay(canvas: Canvas) {
        canvas.drawRect(Rect(0, 0, width, mDefaultFrame.top.toInt()), overlayPaint)        // TOP
        canvas.drawRect(                                                                            // Left
            Rect(
                0,
                mDefaultFrame.top.toInt(),
                mDefaultFrame.left.toInt(),
                mDefaultFrame.bottom.toInt()
            ), overlayPaint
        )
        canvas.drawRect(                                                                            //Right
            Rect(
                mDefaultFrame.right.toInt(),
                mDefaultFrame.top.toInt(),
                width,
                mDefaultFrame.bottom.toInt()
            ), overlayPaint
        )
        canvas.drawRect(Rect(0, mDefaultFrame.bottom.toInt(), width, height), overlayPaint)     //Bottom
    }

    private fun drawBorder(canvas: Canvas) {
//        canvas.drawRect(mDefaultFrame, borderPaint)
        val drawable = resources.getDrawable(R.drawable.qr_scanner, null)
        drawable.bounds = mRectFrame
        drawable.draw(canvas)
    }

    private fun drawLaser(canvas: Canvas, timeElapsed: Long) {
        if (laserY > mDefaultFrame.bottom || laserY < mDefaultFrame.top ) laserY =
            mDefaultFrame.top.toInt()
        canvas.drawLine(
            mDefaultFrame.left + STROKE_WIDTH + 30,
            laserY.toFloat(),
            mDefaultFrame.right - STROKE_WIDTH - 30,
            laserY.toFloat() ,
            laserPaint
        )
        laserY += (timeElapsed / ANIMATION_SPEED).toInt()
    }

    fun setFrameColor(@ColorInt borderColor: Int) {
        borderPaint.color = borderColor
    }

    fun setLaserColor(@ColorInt laserColor: Int) {
        laserPaint.color = laserColor
    }

    fun isQRInsideFrame(qrCodeRect: RectF): Boolean {
        return mDefaultFrame.contains(qrCodeRect)
    }

    companion object {
        private const val STROKE_WIDTH = 5
        private const val ANIMATION_SPEED = 8
        private const val RECTANGLE_WIDTH = 300f
        private const val RECTANGLE_HEIGHT = 300f
    }

    init {
        init(context)
    }
}
