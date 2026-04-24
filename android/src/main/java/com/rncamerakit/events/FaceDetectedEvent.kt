package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event
import com.rncamerakit.FacePayload

class FaceDetectedEvent(
    surfaceId: Int,
    viewId: Int,
    private val faces: List<FacePayload>,
) : Event<FaceDetectedEvent>(surfaceId, viewId) {
    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap {
        val array = Arguments.createArray()
        for (face in faces) {
            val map = Arguments.createMap().apply {
                putInt("id", face.id)
                putDouble("yaw", face.yaw)
                putDouble("pitch", face.pitch)
                putDouble("roll", face.roll)
                putDouble("boundsX", face.boundsX)
                putDouble("boundsY", face.boundsY)
                putDouble("boundsWidth", face.boundsWidth)
                putDouble("boundsHeight", face.boundsHeight)
            }
            array.pushMap(map)
        }
        return Arguments.createMap().apply { putArray("faces", array) }
    }

    companion object {
        const val EVENT_NAME = "topFaceDetected"
    }
}
