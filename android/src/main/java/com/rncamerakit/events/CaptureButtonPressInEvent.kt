package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class CaptureButtonPressInEvent(
    surfaceId: Int,
    viewId: Int,
    private val keyCode: Int,
) : Event<CaptureButtonPressInEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putInt("keyCode", keyCode)
        }

    companion object {
        const val EVENT_NAME = "captureButtonPressIn"
    }
}
