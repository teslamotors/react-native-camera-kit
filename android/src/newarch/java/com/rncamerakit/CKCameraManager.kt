package com.rncamerakit

import android.graphics.Color
import android.util.Log
import android.util.Size
import androidx.annotation.ColorInt
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.common.MapBuilder
import com.facebook.react.common.ReactConstants.TAG
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.CKCameraManagerDelegate
import com.facebook.react.viewmanagers.CKCameraManagerInterface

import com.rncamerakit.events.*

class CKCameraManager(context: ReactApplicationContext) : SimpleViewManager<CKCamera>(), CKCameraManagerInterface<CKCamera> {
    private val delegate: ViewManagerDelegate<CKCamera> = CKCameraManagerDelegate(this)

    override fun getDelegate(): ViewManagerDelegate<CKCamera> = delegate

    override fun getName() : String {
        return "CKCamera"
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
            OrientationChangeEvent.EVENT_NAME, MapBuilder.of("registrationName", "onOrientationChange"),
            ReadCodeEvent.EVENT_NAME, MapBuilder.of("registrationName", "onReadCode"),
            PictureTakenEvent.EVENT_NAME, MapBuilder.of("registrationName", "onPictureTaken"),
            ZoomEvent.EVENT_NAME, MapBuilder.of("registrationName", "onZoom"),
            ErrorEvent.EVENT_NAME, MapBuilder.of("registrationName", "onError"),
            CaptureButtonPressInEvent.EVENT_NAME, MapBuilder.of("registrationName", "onCaptureButtonPressIn"),
            CaptureButtonPressOutEvent.EVENT_NAME, MapBuilder.of("registrationName", "onCaptureButtonPressOut")
        )
    }

    @ReactProp(name = "cameraType")
    override fun setCameraType(view: CKCamera, type: String?) {
        view.setCameraType(type ?: "back")
    }

    @ReactProp(name = "flashMode")
    override fun setFlashMode(view: CKCamera, mode: String?) {
        view.setFlashMode(mode)
    }

    @ReactProp(name = "torchMode")
    override fun setTorchMode(view: CKCamera, mode: String?) {
        view.setTorchMode(mode)
    }

    @ReactProp(name = "focusMode")
    override fun setFocusMode(view: CKCamera, mode: String?) {
        view.setAutoFocus(mode ?: "on")
    }

    @ReactProp(name = "zoomMode")
    override fun setZoomMode(view: CKCamera, mode: String?) {
        view.setZoomMode(mode)
    }

    @ReactProp(name = "zoom", defaultDouble = -1.0)
    override fun setZoom(view: CKCamera, factor: Double) {
        view.setZoom(if (factor == -1.0) null else factor)
    }

    @ReactProp(name = "maxZoom", defaultDouble = 420.0)
    override fun setMaxZoom(view: CKCamera, factor: Double) {
        view.setMaxZoom(factor)
    }

    @ReactProp(name = "scanBarcode")
    override fun setScanBarcode(view: CKCamera, enabled: Boolean) {
        view.setScanBarcode(enabled)
    }

    @ReactProp(name = "showFrame")
    override fun setShowFrame(view: CKCamera, enabled: Boolean) {
        view.setShowFrame(enabled)
    }

    @ReactProp(name = "laserColor", defaultInt = Color.RED)
    override fun setLaserColor(view: CKCamera, @ColorInt color: Int?) {
        view.setLaserColor(color ?: Color.RED)
    }

    @ReactProp(name = "frameColor", defaultInt = Color.GREEN)
    override fun setFrameColor(view: CKCamera, @ColorInt color: Int?) {
        view.setFrameColor(color ?: Color.GREEN)
    }

    @ReactProp(name = "barcodeFrameSize")
    override fun setBarcodeFrameSize(view: CKCamera, frameSize: ReadableMap?) {
        if (frameSize == null || !frameSize.hasKey("width") || !frameSize.hasKey("height")) {
            return
        }
        val width = frameSize.getInt("width")
        val height = frameSize.getInt("height")
        view.setBarcodeFrameSize(Size(width, height))
    }

    @ReactProp(name = "outputPath")
    override fun setOutputPath(view: CKCamera, path: String?) {
        view.setOutputPath(path ?: "")
    }

    @ReactProp(name = "shutterAnimationDuration")
    override fun setShutterAnimationDuration(view: CKCamera, duration: Int) {
        view.setShutterAnimationDuration(duration)
    }

    @ReactProp(name = "shutterPhotoSound")
    override fun setShutterPhotoSound(view: CKCamera, enabled: Boolean) {
        view.setShutterPhotoSound(enabled);
    }

    @ReactProp(name = "scanThrottleDelay")
    override fun setScanThrottleDelay(view: CKCamera?, value: Int) {
        view?.setScanThrottleDelay(value)
    }

    // Methods only available on iOS
    override fun setRatioOverlay(view: CKCamera?, value: String?) = Unit

    override fun setRatioOverlayColor(view: CKCamera?, value: Int?) = Unit

    override fun setResetFocusTimeout(view: CKCamera?, value: Int) = Unit

    override fun setResetFocusWhenMotionDetected(view: CKCamera?, value: Boolean) = Unit

    override fun setResizeMode(view: CKCamera?, value: String?) = Unit

    override fun setMaxPhotoQualityPrioritization(view: CKCamera?, value: String?) = Unit
}
