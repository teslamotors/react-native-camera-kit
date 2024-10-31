package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class ErrorEvent(
    surfaceId: Int,
    viewId: Int,
    private val errorMessage: String?,
) : Event<ErrorEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap =
        Arguments.createMap().apply {
            putString("errorMessage", errorMessage)
        }

    companion object {
        const val EVENT_NAME = "topError"
    }
}
