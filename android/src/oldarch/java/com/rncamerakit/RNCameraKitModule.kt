package com.rncamerakit

import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerHelper

/**
 * Native module for interacting with the camera in React Native applications.
 *
 * This module provides methods to capture photos using the camera and constants
 * related to camera orientation.
 *
 * @param reactContext The application's ReactApplicationContext.
 */
class RNCameraKitModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    companion object {
        // Constants for camera orientation
        /**
         * Represents the portrait orientation with the top of the device up.
         */
        const val PORTRAIT = 0 // ⬆️

        /**
         * Represents the landscape orientation with the left side of the device up.
         */
        const val LANDSCAPE_LEFT = 1 // ⬅️

        /**
         * Represents the portrait orientation with the bottom of the device up.
         */
        const val PORTRAIT_UPSIDE_DOWN = 2 // ⬇️

        /**
         * Represents the landscape orientation with the right side of the device up.
         */
        const val LANDSCAPE_RIGHT = 3 // ➡️

        const val REACT_CLASS = "RNCameraKitModule"
    }

    override fun getName(): String {
        return REACT_CLASS
    }

    /**
     * Provides constants related to camera orientation.
     *
     * @return A map containing camera orientation constants.
     */
    override fun getConstants(): Map<String, Any> {
        return hashMapOf(
            "PORTRAIT" to PORTRAIT,
            "PORTRAIT_UPSIDE_DOWN" to PORTRAIT_UPSIDE_DOWN,
            "LANDSCAPE_LEFT" to LANDSCAPE_LEFT,
            "LANDSCAPE_RIGHT" to LANDSCAPE_RIGHT
        )
    }

    fun requestDeviceCameraAuthorization(promise: Promise?) = Unit

    fun checkDeviceCameraAuthorizationStatus(promise: Promise?) = Unit

    /**
     * Captures a photo using the camera.
     *
     * @param options The options for the capture operation.
     * @param tag The tag of the camera view.
     * @param promise The promise to resolve the capture result.
     */
    @ReactMethod
    fun capture(options: ReadableMap?, tag: Double?, promise: Promise) {
        val viewTag = tag?.toInt()
        if (viewTag != null && options != null) {
            val uiManager = UIManagerHelper.getUIManagerForReactTag(reactContext, viewTag)
            reactContext.runOnUiQueueThread {
                val camera = uiManager?.resolveView(viewTag) as CKCamera
                val optionsMap = options.toHashMap()
                    .mapValues { (_, value) ->
                        when (value) {
                            is ReadableMap -> value.toHashMap()
                            is ReadableArray -> value.toArrayList()
                            else -> value
                        }
                    }
                    .mapNotNull { (key, value) ->
                        if (value != null) key to value else null
                    }
                    .toMap()
                camera.capture(optionsMap, promise)
            }
        } else {
            promise.reject("E_CAPTURE_FAILED", "options or/and tag arguments are null, options: $options, tag: $viewTag")
        }
    }
}
