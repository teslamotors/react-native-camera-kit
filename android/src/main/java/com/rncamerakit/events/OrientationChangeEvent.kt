package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class OrientationChangeEvent(
    surfaceId: Int,
    viewId: Int,
    private val orientation: Int,
) : Event<OrientationChangeEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putInt("orientation", orientation)
        }

    companion object {
        const val EVENT_NAME = "topOrientationChange"
    }
}
