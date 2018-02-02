package com.wix.RNCameraKit.camera.view

import android.annotation.SuppressLint
import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.widget.FrameLayout

/**
 * Created by minggong on 01/02/2018.
 */
class FocusView
@JvmOverloads constructor(
        context: Context,
        attrs: AttributeSet? = null,
        defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val visualFeedbackCircle = FeedbackCircleView(context, attrs, defStyleAttr)
    private var cameraAreasUpdateListener: CameraAreasUpdateListener? = null

    init {
        clipToPadding = false
        clipChildren = false
        addView(visualFeedbackCircle)
    }

    fun setCameAreasUpdateListener(listener: CameraAreasUpdateListener) {
        this.cameraAreasUpdateListener = listener
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action == MotionEvent.ACTION_DOWN) {
            val focalRequest = FocalRequest(
                    point = PointF(x = event.x, y = event.y),
                    previewResolution = Resolution(width = width, height = height)
            )
            val calculatedFocusAreas = focalRequest.toFocusAreas(Orientation.PORTRAIT_ROTATION, false)
            cameraAreasUpdateListener?.let {
                it.onCameraAreasUpdated(calculatedFocusAreas)
                visualFeedbackCircle.showAt(
                        x = event.x - visualFeedbackCircle.width / 2,
                        y = event.y - visualFeedbackCircle.height / 2
                )
            }
        }
        return super.onTouchEvent(event)
    }

}
