package com.rncamerakit.events

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.Event

data class ReadCodePayload(
    val codeStringValue: String?,
    val codeFormat: String,
)

class ReadCodeEvent(
    surfaceId: Int,
    viewId: Int,
    private val codes: List<ReadCodePayload>,
) : Event<ReadCodeEvent>(surfaceId, viewId) {
    // Kept for source compatibility with the previous single-code signature
    constructor(
        surfaceId: Int,
        viewId: Int,
        codeStringValue: String?,
        codeFormat: String,
    ) : this(surfaceId, viewId, listOf(ReadCodePayload(codeStringValue, codeFormat)))

    override fun getEventName(): String = EVENT_NAME

    override fun getEventData(): WritableMap {
        val array = Arguments.createArray()
        for (code in codes) {
            val map = Arguments.createMap().apply {
                putString("codeFormat", code.codeFormat)
                putString("codeStringValue", code.codeStringValue)
            }
            array.pushMap(map)
        }
        // Top-level fields mirror the first code for backward compatibility
        val first = codes.firstOrNull()
        return Arguments.createMap().apply {
            putString("codeFormat", first?.codeFormat)
            putString("codeStringValue", first?.codeStringValue)
            putArray("codes", array)
        }
    }

    companion object {
        const val EVENT_NAME = "topReadCode"
    }
}
