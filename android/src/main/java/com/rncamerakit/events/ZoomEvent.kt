package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class ZoomEvent(
    surfaceId: Int,
    viewId: Int,
    private val zoom: Double,
) : Event<ZoomEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putDouble("zoom", zoom)
        }

    companion object {
        const val EVENT_NAME = "topZoom"
    }
}
