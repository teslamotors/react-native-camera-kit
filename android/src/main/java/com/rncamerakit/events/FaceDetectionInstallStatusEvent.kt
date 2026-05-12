package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

class FaceDetectionInstallStatusEvent(
    surfaceId: Int,
    viewId: Int,
    private val state: String,
) : Event<FaceDetectionInstallStatusEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap = Arguments.createMap().apply {
        putString("state", state)
    }

    companion object {
        const val EVENT_NAME = "topFaceDetectionInstallStatus"
    }
}
