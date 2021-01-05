package com.rncamerakit

import android.util.Log
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableType
import com.facebook.react.common.MapBuilder
import com.facebook.react.common.ReactConstants.TAG
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp

class CKCameraManager : SimpleViewManager<CKCamera>() {

    override fun getName() : String {
        return "CKCameraManager"
    }

    override fun createViewInstance(context: ThemedReactContext): CKCamera {
        return CKCamera(context)
    }

    override fun receiveCommand(view: CKCamera, commandId: String?, args: ReadableArray?) {
        var logCommand = "CameraManager received command $commandId("
        for (i in 0..(args?.size() ?: 0)) {
            if (i > 0) {
                logCommand += ", "
            }
            logCommand += when (args?.getType(0)) {
                ReadableType.Null -> "Null"
                ReadableType.Array -> "Array"
                ReadableType.Boolean -> "Boolean"
                ReadableType.Map -> "Map"
                ReadableType.Number -> "Number"
                ReadableType.String -> "String"
                else ->  ""
            }
        }
        logCommand += ")"
        Log.d(TAG, logCommand)
    }

    override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
        return MapBuilder.of(
                "onOrientationChange", MapBuilder.of("registrationName", "onOrientationChange"),
                "onBarcodeRead", MapBuilder.of("registrationName", "onBarcodeRead"),
                "onPictureTaken", MapBuilder.of("registrationName", "onPictureTaken")
        )
    }

    @ReactProp(name = "flashMode")
    fun setFlashMode(view: CKCamera, mode: String?) {
        view.setFlashMode(mode)
    }

    @ReactProp(name = "focusMode")
    fun setFocusMode(view: CKCamera, mode: String) {
        view.setAutoFocus(mode)
    }

    @ReactProp(name = "zoomMode")
    fun setZoomMode(view: CKCamera, mode: String) {
        view.setZoomMode(mode)
    }

    @ReactProp(name = "scanBarcode")
    fun setScanBarcode(view: CKCamera, enabled: Boolean) {
        view.setScanBarcode(enabled)
    }

    @ReactProp(name = "type")
    fun setType(view: CKCamera, type: String) {
        view.setType(type)
    }

    @ReactProp(name = "outputPath")
    fun setOutputPath(view: CKCamera, path: String) {
        view.setOutputPath(path)
    }

    @ReactProp(name = "shutterAnimationDuration")
    fun setShutterAnimationDuration(view: CKCamera, duration: Int) {
        view.setShutterAnimationDuration(duration)
    }
}