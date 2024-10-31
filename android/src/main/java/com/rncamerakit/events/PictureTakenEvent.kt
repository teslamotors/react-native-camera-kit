package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class PictureTakenEvent(
    surfaceId: Int,
    viewId: Int,
    private val uri: String,
) : Event<PictureTakenEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putString("uri", uri)
        }

    companion object {
        const val EVENT_NAME = "topPictureTaken"
    }
}
