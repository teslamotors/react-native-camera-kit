package com.rncamerakit.barcode

import android.content.Context
import android.graphics.*
import android.view.View
import androidx.annotation.ColorInt

class BarcodeFrame(context: Context) : View(context) {
    private var borderPaint: Paint = Paint()
    private var laserPaint: Paint = Paint()
    private var previousFrameTime = System.currentTimeMillis()
    private var laserY = 0

    private var mDefaultFrame = RectF()
    private var mCanvas = Canvas()

    private fun init(context: Context) {
        borderPaint = Paint()
        borderPaint.style = Paint.Style.STROKE
        borderPaint.strokeWidth = STROKE_WIDTH.toFloat()
        laserPaint.style = Paint.Style.STROKE
        laserPaint.strokeWidth = STROKE_WIDTH.toFloat()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val centerX = width / 2f
        val centerY = (height / 2f) + (RECTANGLE_HEIGHT / 2f)
        mDefaultFrame.left = centerX - RECTANGLE_WIDTH
        mDefaultFrame.top = centerY - RECTANGLE_HEIGHT
        mDefaultFrame.right = centerX + RECTANGLE_WIDTH
        mDefaultFrame.bottom = centerY + RECTANGLE_HEIGHT
    }

    override fun onDraw(canvas: Canvas) {
        val timeElapsed = System.currentTimeMillis() - previousFrameTime
        super.onDraw(canvas)
        mCanvas = canvas
        drawBorder(canvas)
        drawLaser(canvas, timeElapsed)
        previousFrameTime = System.currentTimeMillis()
        invalidate()
    }

    private fun drawBorder(canvas: Canvas) {
        canvas.drawRect(mDefaultFrame, borderPaint)
    }

    private fun drawLaser(canvas: Canvas, timeElapsed: Long) {
        if (laserY > mDefaultFrame.bottom || laserY < mDefaultFrame.top) laserY =
            mDefaultFrame.top.toInt()
        canvas.drawLine(
            mDefaultFrame.left + STROKE_WIDTH,
            laserY.toFloat(),
            mDefaultFrame.right - STROKE_WIDTH,
            laserY.toFloat(),
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
