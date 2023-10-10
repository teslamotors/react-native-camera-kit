package com.rncamerakit

import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerModule

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
    }

    override fun getName(): String {
        return "RNCameraKitModule"
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

    /**
     * Captures a photo using the camera.
     *
     * @param options The options for the capture operation.
     * @param viewTag The tag of the camera view.
     * @param promise The promise to resolve the capture result.
     */
    @ReactMethod
    fun capture(options: ReadableMap, viewTag: Int, promise: Promise) {
        // CameraManager does not allow us to return values
        val context = reactContext
        val uiManager = context.getNativeModule(UIManagerModule::class.java)
        context.runOnUiQueueThread {
            val view = uiManager?.resolveView(viewTag) as CKCamera
            view.capture(options.toHashMap(), promise)
        }
    }
}
