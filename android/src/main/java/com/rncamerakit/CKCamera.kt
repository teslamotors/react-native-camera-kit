package com.rncamerakit

import android.Manifest
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.SensorManager
import android.media.AudioManager
import android.media.MediaActionSound
import android.net.Uri
import android.util.DisplayMetrics
import android.util.Log
import android.view.*
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.annotation.ColorInt
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleObserver
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.rncamerakit.barcode.BarcodeFrame
import java.io.File
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import com.facebook.react.uimanager.UIManagerHelper
import com.google.mlkit.vision.barcode.common.Barcode
import com.rncamerakit.events.*

class RectOverlay constructor(context: Context) :
        View(context) {

    private val rectBounds: MutableList<RectF> = mutableListOf()
    private val paint = Paint().apply {
        style = Paint.Style.STROKE
        color = ContextCompat.getColor(context, android.R.color.holo_green_light)
        strokeWidth = 5f
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        // Pass it a list of RectF (rectBounds)
        rectBounds.forEach { canvas.drawRect(it, paint) }
    }

    fun drawRectBounds(rectBounds: List<RectF>) {
        this.rectBounds.clear()
        this.rectBounds.addAll(rectBounds)
        invalidate()
        postDelayed({
          this.rectBounds.clear()
          invalidate()
        }, 1000)
    }
}

@SuppressLint("ViewConstructor") // Extra constructors unused. Not using visual layout tools
class CKCamera(context: ThemedReactContext) : FrameLayout(context), LifecycleObserver {
    private val currentContext: ThemedReactContext = context

    private var camera: Camera? = null
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var imageAnalyzer: ImageAnalysis? = null
    private var orientationListener: OrientationEventListener? = null
    private var viewFinder: PreviewView = PreviewView(context)
    private var rectOverlay: RectOverlay = RectOverlay(context)
    private var barcodeFrame: BarcodeFrame? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var outputPath: String? = null
    private var shutterAnimationDuration: Int = 50
    private var shutterPhotoSound: Boolean = true
    private var effectLayer = View(context)

    // Camera Props
    private var lensType = CameraSelector.LENS_FACING_BACK
    private var autoFocus = "on"
    private var zoomMode = "on"
    private var lastOnZoom = 0.0
    private var zoom: Double? = null
    private var maxZoom: Double? = null
    private var zoomStartedAt = 1.0f
    private var pinchGestureStartedAt = 0.0f

    // Barcode Props
    private var scanBarcode: Boolean = false
    private var frameColor = Color.GREEN
    private var laserColor = Color.RED

    private fun getActivity() : Activity {
        return currentContext.currentActivity!!
    }

    init {
        viewFinder.layoutParams = LinearLayout.LayoutParams(
                LayoutParams.MATCH_PARENT,
                LayoutParams.MATCH_PARENT
        )
        installHierarchyFitter(viewFinder)
        addView(viewFinder)

        effectLayer.alpha = 0F
        effectLayer.setBackgroundColor(Color.BLACK)
        addView(effectLayer)
        addView(rectOverlay)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        if (hasPermissions()) {
            viewFinder.post { setupCamera() }
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()

        cameraExecutor.shutdown()
        orientationListener?.disable()
        cameraProvider?.unbindAll()
    }

    // If this is not called correctly, view finder will be black/blank
    // https://github.com/facebook/react-native/issues/17968#issuecomment-633308615
    private fun installHierarchyFitter(view: ViewGroup) {
        Log.d(TAG, "CameraView looking for ThemedReactContext")
        if (context is ThemedReactContext) { // only react-native setup
            Log.d(TAG, "CameraView found ThemedReactContext")
            view.setOnHierarchyChangeListener(object : OnHierarchyChangeListener {
                override fun onChildViewRemoved(parent: View?, child: View?) = Unit
                override fun onChildViewAdded(parent: View?, child: View?) {
                    parent?.measure(
                            MeasureSpec.makeMeasureSpec(measuredWidth, MeasureSpec.EXACTLY),
                            MeasureSpec.makeMeasureSpec(measuredHeight, MeasureSpec.EXACTLY)
                    )
                    parent?.layout(0, 0, parent.measuredWidth, parent.measuredHeight)
                }
            })
        }
    }

    /** Initialize CameraX, and prepare to bind the camera use cases  */
    @SuppressLint("ClickableViewAccessibility")
    private fun setupCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(getActivity())
        cameraProviderFuture.addListener({
            // Used to bind the lifecycle of cameras to the lifecycle owner
            cameraProvider = cameraProviderFuture.get()

            // Rotate the image according to device orientation, even when UI orientation is locked
            orientationListener = object : OrientationEventListener(context, SensorManager.SENSOR_DELAY_UI) {
                override fun onOrientationChanged(orientation: Int) {
                    val imageCapture = imageCapture ?: return
                    var newOrientation: Int = imageCapture.targetRotation
                    if (orientation >= 315 || orientation < 45) {
                        newOrientation = Surface.ROTATION_0
                    } else if (orientation in 225..314) {
                        newOrientation = Surface.ROTATION_90
                    } else if (orientation in 135..224) {
                        newOrientation = Surface.ROTATION_180
                    } else if (orientation in 45..134) {
                        newOrientation = Surface.ROTATION_270
                    }
                    if (newOrientation != imageCapture.targetRotation) {
                        imageCapture.targetRotation = newOrientation
                        onOrientationChange(newOrientation)
                    }
                }
            }
            orientationListener!!.enable()

            val scaleDetector =  ScaleGestureDetector(context, object: ScaleGestureDetector.SimpleOnScaleGestureListener() {
                override fun onScaleBegin(detector: ScaleGestureDetector): Boolean {
                    val cameraZoom = camera?.cameraInfo?.zoomState?.value?.zoomRatio ?: return false
                    detector ?: return false
                    zoomStartedAt = cameraZoom
                    pinchGestureStartedAt = detector.currentSpan
                    return true
                }
                override fun onScale(detector: ScaleGestureDetector): Boolean {
                    if (zoomMode == "off") return true
                    if (detector == null) return true
                    val videoDevice = camera ?: return true
                    val pinchScale = detector.currentSpan / pinchGestureStartedAt

                    val desiredZoomFactor = zoomStartedAt * pinchScale
                    val zoomForDevice = getValidZoom(videoDevice, desiredZoomFactor.toDouble())

                    if (zoomForDevice != (videoDevice.cameraInfo.zoomState.value?.zoomRatio ?: -1)) {
                        // Only trigger zoom changes if it's an uncontrolled component (zoom isn't manually set)
                        // otherwise it's likely to cause issues inf. loops
                        if (zoom == null) {
                            videoDevice.cameraControl.setZoomRatio(zoomForDevice.toFloat())
                        }
                        onZoom(zoomForDevice)
                    }
                    return true
                }
            })

            // Tap to focus
            viewFinder.setOnTouchListener { _, event ->
                if (event.action != MotionEvent.ACTION_UP) {
                    return@setOnTouchListener scaleDetector.onTouchEvent(event)
                }
                focusOnPoint(event.x, event.y)
                return@setOnTouchListener true
            }

            bindCameraUseCases()
        }, ContextCompat.getMainExecutor(getActivity()))
    }

    private fun setZoomFor(videoDevice: Camera, zoom: Double) {
        videoDevice.cameraControl.setZoomRatio(zoom.toFloat())
    }

    private fun resetZoom(videoDevice: Camera) {
        var zoomForDevice = getValidZoom(videoDevice, 1.0)
        val zoomPropValue = this.zoom
        if (zoomPropValue != null) {
            zoomForDevice = getValidZoom(videoDevice, zoomPropValue)
        }
        setZoomFor(videoDevice, zoomForDevice)
        this.onZoom(zoomForDevice)
    }

    private fun getValidZoom(videoDevice: Camera?, zoom: Double): Double {
        var zoomOrDefault = zoom
        val minZoomFactor = videoDevice?.cameraInfo?.zoomState?.value?.minZoomRatio?.toDouble()
        var maxZoomFactor: Double? = videoDevice?.cameraInfo?.zoomState?.value?.maxZoomRatio?.toDouble()
        val maxZoom = this.maxZoom
        if (maxZoom != null) {
            maxZoomFactor = min(maxZoomFactor ?: maxZoom, maxZoom)
        }
        if (maxZoomFactor != null) {
            zoomOrDefault = min(zoomOrDefault, maxZoomFactor)
        }
        if (minZoomFactor != null) {
            zoomOrDefault = max(zoomOrDefault, minZoomFactor)
        }
        return zoomOrDefault
    }

    private fun bindCameraUseCases() {
        if (viewFinder.display == null) return
        // Get screen metrics used to setup camera for full screen resolution
        val metrics = DisplayMetrics().also { viewFinder.display.getRealMetrics(it) }
        Log.d(TAG, "Screen metrics: ${metrics.widthPixels} x ${metrics.heightPixels}")

        val screenAspectRatio = aspectRatio(metrics.widthPixels, metrics.heightPixels)
        Log.d(TAG, "Preview aspect ratio: $screenAspectRatio")

        val rotation = viewFinder.display.rotation

        // CameraProvider
        val cameraProvider = cameraProvider
                ?: throw IllegalStateException("Camera initialization failed.")

        // CameraSelector
        val cameraSelector = CameraSelector.Builder().requireLensFacing(lensType).build()

        // Preview
        preview = Preview.Builder()
                // We request aspect ratio but no resolution
                .setTargetAspectRatio(screenAspectRatio)
                // Set initial target rotation
                .setTargetRotation(rotation)
                .build()

        // ImageCapture
        imageCapture = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            // We request aspect ratio but no resolution to match preview config, but letting
            // CameraX optimize for whatever specific resolution best fits our use cases
            .setTargetAspectRatio(screenAspectRatio)
            // Set initial target rotation, we will have to call this again if rotation changes
            // during the lifecycle of this use case
            .setTargetRotation(rotation)
            .build()

        // ImageAnalysis
        imageAnalyzer = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setTargetAspectRatio(screenAspectRatio)
            .build()

        val useCases = mutableListOf(preview, imageCapture)

        if (scanBarcode) {
            val analyzer = QRCodeAnalyzer { barcodes, imageSize ->
                if (barcodes.isEmpty()) {
                    return@QRCodeAnalyzer
                }

                val barcodeFrame = barcodeFrame;
                if (barcodeFrame == null) {
                    onBarcodeRead(barcodes)
                    return@QRCodeAnalyzer
                }

                // Calculate scaling factors (image is always rotated by 90 degrees)
                val scaleX = viewFinder.width.toFloat() / imageSize.height
                val scaleY = viewFinder.height.toFloat() / imageSize.width

                val filteredBarcodes = barcodes.filter { barcode ->
                    val barcodeBoundingBox = barcode.boundingBox ?: return@filter false;
                    val scaledBarcodeBoundingBox = Rect(
                        (barcodeBoundingBox.left * scaleX).toInt(),
                        (barcodeBoundingBox.top * scaleY).toInt(),
                        (barcodeBoundingBox.right * scaleX).toInt(),
                        (barcodeBoundingBox.bottom * scaleY).toInt()
                    )
                    barcodeFrame.frameRect.contains(scaledBarcodeBoundingBox)
                }

                if (filteredBarcodes.isNotEmpty()) {
                    onBarcodeRead(filteredBarcodes)
                }
            }
            imageAnalyzer!!.setAnalyzer(cameraExecutor, analyzer)
            useCases.add(imageAnalyzer)
        }

        // Must unbind the use-cases before rebinding them
        cameraProvider.unbindAll()

        try {
            // A variable number of use-cases can be passed here -
            // camera provides access to CameraControl & CameraInfo
            val newCamera = cameraProvider.bindToLifecycle(getActivity() as AppCompatActivity, cameraSelector, *useCases.toTypedArray())
            camera = newCamera

            resetZoom(newCamera)

            // Attach the viewfinder's surface provider to preview use case
            preview?.setSurfaceProvider(viewFinder.surfaceProvider)
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)

            val surfaceId = UIManagerHelper.getSurfaceId(currentContext)
            UIManagerHelper
                .getEventDispatcherForReactTag(currentContext, id)
                ?.dispatchEvent(ErrorEvent(surfaceId, id, exc.message))
        }
    }

    /**
     *  [androidx.camera.core.ImageAnalysisConfig] requires enum value of
     *  [androidx.camera.core.AspectRatio]. Currently it has values of 4:3 & 16:9.
     *
     *  Detecting the most suitable ratio for dimensions provided in @params by counting absolute
     *  of preview ratio to one of the provided values.
     *
     *  @param width - preview width
     *  @param height - preview height
     *  @return suitable aspect ratio
     */
    private fun aspectRatio(width: Int, height: Int): Int {
        val previewRatio = max(width, height).toDouble() / min(width, height)
        if (abs(previewRatio - RATIO_4_3_VALUE) <= abs(previewRatio - RATIO_16_9_VALUE)) {
            return AspectRatio.RATIO_4_3
        }
        return AspectRatio.RATIO_16_9
    }

    private fun flashViewFinder() {
        if (shutterAnimationDuration == 0) return

        effectLayer
                .animate()
                .alpha(1F)
                .setDuration(shutterAnimationDuration.toLong())
                .setListener(object : AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: Animator) {
                        effectLayer.animate().alpha(0F).duration = shutterAnimationDuration.toLong()
                    }
                }).start()
    }

    fun setShutterAnimationDuration(duration: Int) {
        shutterAnimationDuration = duration
    }

    fun setShutterPhotoSound(enabled: Boolean) {
        shutterPhotoSound = enabled;
    }

    fun capture(options: Map<String, Any>, promise: Promise) {
        // Create the output file option to store the captured image in MediaStore
        val outputPath: String = when {
            outputPath != null -> outputPath!!
            else -> {
                val out = File.createTempFile("ckcap", ".jpg", context.cacheDir)
                out.deleteOnExit()
                out.canonicalPath
            }
        }

        val outputFile = File(outputPath)
        val outputOptions = ImageCapture.OutputFileOptions
                    .Builder(outputFile)
                    .build()

        flashViewFinder()

        if (shutterPhotoSound) {
            val audio = getActivity().getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (audio.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
                MediaActionSound().play(MediaActionSound.SHUTTER_CLICK)
            }
        }

        // Setup image capture listener which is triggered after photo has been taken
        imageCapture?.takePicture(
                outputOptions, ContextCompat.getMainExecutor(getActivity()), object : ImageCapture.OnImageSavedCallback {
            override fun onError(ex: ImageCaptureException) {
                Log.e(TAG, "CameraView: Photo capture failed: ${ex.message}", ex)
                promise.reject("E_CAPTURE_FAILED", "takePicture failed: ${ex.message}")
            }

            override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                try {
                    val uri = output.savedUri ?: Uri.fromFile(outputFile)
                    val id = uri?.path
                    val name = uri?.lastPathSegment
                    val path = uri?.path

                    val savedUri = (output.savedUri ?: outputPath).toString()
                    onPictureTaken(savedUri)
                    Log.d(TAG, "CameraView: Photo capture succeeded: $savedUri")

                    val imageInfo = Arguments.createMap()
                    imageInfo.putString("uri", uri.toString())
                    imageInfo.putString("id", id)
                    imageInfo.putString("name", name)
                    imageInfo.putInt("width", width)
                    imageInfo.putInt("height", height)
                    imageInfo.putString("path", path)

                    promise.resolve(imageInfo)
                } catch (ex: Exception) {
                    Log.e(TAG, "Error while saving or decoding saved photo: ${ex.message}", ex)
                    promise.reject("E_ON_IMG_SAVED", "Error while reading saved photo: ${ex.message}")
                }
            }
        })
    }

    private fun focusOnPoint(x: Float?, y: Float?) {
        if (x === null || y === null) {
            camera?.cameraControl?.cancelFocusAndMetering()
            return
        }
        val factory = viewFinder.meteringPointFactory
        val builder = FocusMeteringAction.Builder(factory.createPoint(x, y))

        // Auto-cancel will clear focus points (and engage AF) after a duration
        if (autoFocus == "off") builder.disableAutoCancel()

        camera?.cameraControl?.startFocusAndMetering(builder.build())
        val focusRects = listOf(RectF(x-75, y-75, x+75, y+75))
        rectOverlay.drawRectBounds(focusRects)
    }

    private fun onBarcodeRead(barcodes: List<Barcode>) {
        val codeFormat = CodeFormat.fromBarcodeType(barcodes.first().format);
        val surfaceId = UIManagerHelper.getSurfaceId(currentContext)
        UIManagerHelper
            .getEventDispatcherForReactTag(currentContext, id)
            ?.dispatchEvent(ReadCodeEvent(surfaceId, id, barcodes.first().rawValue, codeFormat.code))
    }

    private fun onOrientationChange(orientation: Int) {
        val remappedOrientation = when (orientation) {
            Surface.ROTATION_0 -> RNCameraKitModule.PORTRAIT
            Surface.ROTATION_90 -> RNCameraKitModule.LANDSCAPE_LEFT
            Surface.ROTATION_180 -> RNCameraKitModule.PORTRAIT_UPSIDE_DOWN
            Surface.ROTATION_270 -> RNCameraKitModule.LANDSCAPE_RIGHT
            else -> {
                Log.e(TAG, "CameraView: Unknown device orientation detected: $orientation")
                return
            }
        }

        val surfaceId = UIManagerHelper.getSurfaceId(currentContext)
        UIManagerHelper
            .getEventDispatcherForReactTag(currentContext, id)
            ?.dispatchEvent(OrientationChangeEvent(surfaceId, id, remappedOrientation))
    }

    private fun onPictureTaken(uri: String) {
        val surfaceId = UIManagerHelper.getSurfaceId(currentContext)
        UIManagerHelper
            .getEventDispatcherForReactTag(currentContext, id)
            ?.dispatchEvent(PictureTakenEvent(surfaceId, id, uri))
    }

    fun setFlashMode(mode: String?) {
        val imageCapture = imageCapture ?: return
        val camera = camera ?: return
        when (mode) {
            "on" -> {
                camera.cameraControl.enableTorch(false)
                imageCapture.flashMode = ImageCapture.FLASH_MODE_ON
            }
            "off" -> {
                camera.cameraControl.enableTorch(false)
                imageCapture.flashMode = ImageCapture.FLASH_MODE_OFF
            }
            else -> { // 'auto' and any wrong values
                imageCapture.flashMode = ImageCapture.FLASH_MODE_AUTO
                camera.cameraControl.enableTorch(false)
            }
        }
    }

    fun setTorchMode(mode: String?) {
        val camera = camera ?: return
        when (mode) {
            "on" -> {
                camera.cameraControl.enableTorch(true)
            }
            "off" -> {
                camera.cameraControl.enableTorch(false)
            }
            else -> { // 'auto' and any wrong values
                camera.cameraControl.enableTorch(false)
            }
        }
    }

    fun setAutoFocus(mode: String = "on") {
        autoFocus = mode
        when(mode) {
            // "cancel" clear AF points and engages continuous auto-focus
            "on" -> camera?.cameraControl?.cancelFocusAndMetering()
            // 'off': Handled when you tap to focus
        }
    }

    fun setZoomMode(mode: String?) {
        zoomMode = mode ?: "off"
    }

    fun setZoom(factor: Double?) {
        zoom = factor
        var zoomOrDefault = zoom ?: return
        val videoDevice = camera ?: return

        val zoomForDevice = this.getValidZoom(camera, zoomOrDefault)
        this.setZoomFor(videoDevice, zoomForDevice)
    }

    private fun onZoom(desiredZoom: Double?) {
        val cameraZoom = camera?.cameraInfo?.zoomState?.value?.zoomRatio?.toDouble() ?: return
        val desiredOrCameraZoom = desiredZoom ?: cameraZoom
        // ignore duplicate events when zooming to min/max
        // but always notify if a desiredZoom wasn't given,
        // since that means they wanted to reset setZoom(1.0)
        // so we should tell them what zoom it really is
        if (desiredZoom != null && desiredOrCameraZoom == lastOnZoom) {
            return
        }

        lastOnZoom = desiredOrCameraZoom
        val surfaceId = UIManagerHelper.getSurfaceId(currentContext)
        UIManagerHelper
            .getEventDispatcherForReactTag(currentContext, id)
            ?.dispatchEvent(ZoomEvent(surfaceId, id, desiredOrCameraZoom))
    }

    fun setMaxZoom(factor: Double?) {
        maxZoom = factor

        // Re-update zoom value in case the max was increased
        setZoom(zoom)
    }

    fun setScanBarcode(enabled: Boolean) {
        val restartCamera = enabled != scanBarcode
        scanBarcode = enabled
        if (restartCamera) bindCameraUseCases()
    }

    fun setCameraType(type: String = "back") {
        val newLensType = when (type) {
            "front" -> CameraSelector.LENS_FACING_FRONT
            else -> CameraSelector.LENS_FACING_BACK
        }
        val restartCamera = lensType != newLensType
        lensType = newLensType
        if (restartCamera) bindCameraUseCases()
    }

    fun setOutputPath(path: String) {
        outputPath = path
    }

    fun setShowFrame(enabled: Boolean) {
        if (enabled) {
            barcodeFrame = BarcodeFrame(context)
            val actualPreviewWidth = resources.displayMetrics.widthPixels
            val actualPreviewHeight = resources.displayMetrics.heightPixels
            val height: Int = convertDeviceHeightToSupportedAspectRatio(actualPreviewWidth, actualPreviewHeight)
            barcodeFrame!!.setFrameColor(frameColor)
            barcodeFrame!!.setLaserColor(laserColor)
            (barcodeFrame as View).layout(0, 0, this.effectLayer.width, this.effectLayer.height)
            addView(barcodeFrame)
        } else if (barcodeFrame != null) {
            removeView(barcodeFrame)
            barcodeFrame = null
        }
    }

    fun setLaserColor(@ColorInt color: Int) {
        laserColor = color
        if (barcodeFrame != null) {
            barcodeFrame!!.setLaserColor(laserColor)
        }
    }

    fun setFrameColor(@ColorInt color: Int) {
        frameColor = color
        if (barcodeFrame != null) {
            barcodeFrame!!.setFrameColor(color)
        }
    }

    private fun convertDeviceHeightToSupportedAspectRatio(actualWidth: Int, actualHeight: Int): Int {
        val maxScreenRatio = 16 / 9f
        return (if (actualHeight / actualWidth > maxScreenRatio) actualWidth * maxScreenRatio else actualHeight).toInt()
    }

    private fun hasPermissions(): Boolean {
        val requiredPermissions = arrayOf(Manifest.permission.CAMERA)
        if (requiredPermissions.all {
                    ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
                }) {
            return true
        }
        ActivityCompat.requestPermissions(
                getActivity(),
                requiredPermissions,
                42 // random callback identifier
        )
        return false
    }

    companion object {

        private const val TAG = "CameraKit"
        private const val RATIO_4_3_VALUE = 4.0 / 3.0
        private const val RATIO_16_9_VALUE = 16.0 / 9.0
    }
}
