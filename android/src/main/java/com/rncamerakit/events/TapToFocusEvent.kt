package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class TapToFocusEvent(
    surfaceId: Int,
    viewId: Int,
    private val x: Double,
    private val y: Double,
) : Event<TapToFocusEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putDouble("x", x)
            putDouble("y", y)
        }

    companion object {
        const val EVENT_NAME = "topTapToFocus"
    }
}
