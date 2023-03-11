package com.rncamerakit

import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerModule

class RNCameraKitModule(private val reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    companion object {
        // 0-indexed, rotates counter-clockwise
        // Values map to CameraX's Surface.ROTATION_* constants
        const val PORTRAIT = 0 // ⬆️
        const val LANDSCAPE_LEFT = 1 // ⬅️
        const val PORTRAIT_UPSIDE_DOWN = 2 // ⬇️
        const val LANDSCAPE_RIGHT = 3 // ➡️
    }

    override fun getName(): String {
        return "RNCameraKitModule"
    }

    override fun getConstants(): Map<String, Any> {
        return hashMapOf(
                "PORTRAIT" to PORTRAIT,
                "PORTRAIT_UPSIDE_DOWN" to PORTRAIT_UPSIDE_DOWN,
                "LANDSCAPE_LEFT" to LANDSCAPE_LEFT,
                "LANDSCAPE_RIGHT" to LANDSCAPE_RIGHT
        )
    }

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

    @ReactMethod
    fun setTorchMode( mode: String, viewTag: Int) {
        val context = reactContext
        val uiManager = context.getNativeModule(UIManagerModule::class.java)
        context.runOnUiQueueThread {
            val view = uiManager?.resolveView(viewTag) as CKCamera
            view.setTorchMode(mode)
        }

    }
}