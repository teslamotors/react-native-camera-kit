package com.rncamerakit

import android.Manifest
import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.SensorManager
import android.media.AudioManager
import android.media.MediaActionSound
import android.provider.MediaStore
import android.util.Log
import android.view.*
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.WritableMap
import com.facebook.react.common.ReactConstants.TAG
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.events.RCTEventEmitter
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

@SuppressLint("ViewConstructor") // Extra constructors unused. Not using visual layout tools
class CKCamera(context: ThemedReactContext) : FrameLayout(context), LifecycleObserver {
    private val currentContext: ThemedReactContext = context
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var qrCodeAnalyzer: ImageAnalysis? = null
    private var cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
    private var camera: Camera? = null
    private var orientationListener: OrientationEventListener? = null
    private var viewFinder: PreviewView = PreviewView(context)
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var scanBarcode: Boolean = false
    private var lensType = CameraSelector.LENS_FACING_BACK
    private var autoFocus = "on"
    private var cameraProvider: ProcessCameraProvider? = null
    private var outputPath: String? = null
    private var shutterAnimationDuration: Int = 50
    private var effectLayer = View(context)
    private var counter = 0

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

        if (hasPermissions()) {
            viewFinder.post { startCamera() }
        }

        (getActivity() as AppCompatActivity).lifecycle.addObserver(this)
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_RESUME)
    fun onResume() {
        Log.d(TAG, "onResume")
        viewFinder.post { startCamera() }
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
    fun onPause() {
        Log.d(TAG, "onPause")
        stopCamera()
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_DESTROY)
    fun onDestroy() {
        Log.d(TAG, "onDestroy")
        stopCamera()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopCamera()
    }

    private fun stopCamera() {
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

    @SuppressLint("ClickableViewAccessibility")
    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(getActivity())

        val onScaleGestureListener = object: ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector?): Boolean {
                val cameraControl = camera?.cameraControl ?: return true
                val zoom = camera?.cameraInfo?.zoomState?.value?.zoomRatio ?: return true
                val scaleFactor = detector?.scaleFactor ?: return true
                val scale = zoom * scaleFactor

                cameraControl.setZoomRatio(scale)
                return true
            }
        }

        cameraProviderFuture.addListener(Runnable {
            // Used to bind the lifecycle of cameras to the lifecycle owner
            cameraProvider = cameraProviderFuture.get()
            val scaleDetector = ScaleGestureDetector(context, onScaleGestureListener)

            cameraSelector = CameraSelector.Builder().requireLensFacing(lensType).build()
            preview = Preview.Builder().build().also {
                it.setSurfaceProvider(viewFinder.surfaceProvider)
            }
            imageCapture = ImageCapture.Builder().build()

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

            // Contain camera feed image within component bounds, centered
            viewFinder.scaleType = PreviewView.ScaleType.FIT_CENTER

            // Tap to focus
            viewFinder.setOnTouchListener { _, event ->
                if (event.action != MotionEvent.ACTION_UP) {
                    return@setOnTouchListener scaleDetector.onTouchEvent(event)
                }
                focusOnPoint(event.x, event.y)
                return@setOnTouchListener true
            }

            qrCodeAnalyzer = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .build()

            val analyzer = QRCodeAnalyzer { barcodes ->
                if (barcodes.isNotEmpty()) {
                    onBarcodeRead(barcodes)
                }
            }
            qrCodeAnalyzer!!.setAnalyzer(cameraExecutor, analyzer)

            val useCases = mutableListOf(preview, imageCapture)
            if (scanBarcode) useCases.add(qrCodeAnalyzer!!)

            try {
                // Unbind use cases before rebinding
                cameraProvider!!.unbindAll()

                // Bind use cases to camera
                camera = cameraProvider!!.bindToLifecycle(
                        getActivity() as AppCompatActivity,
                        cameraSelector,
                        *useCases.toTypedArray()
                )
                preview!!.setSurfaceProvider(viewFinder.surfaceProvider)
                Log.d(TAG, "CameraView: Use cases bound")
            } catch (exc: Exception) {
                Log.e(TAG, "CameraView: Use cases binding failed", exc)
            }
        }, ContextCompat.getMainExecutor(getActivity()))
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

    fun capture(options: Map<String, Any>, promise: Promise) {
        // Create output options object which contains file + metadata
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "Untitled")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpg")
        }

        // Create the output file option to store the captured image in MediaStore
        val outputOptions = when (outputPath) {
            null -> ImageCapture.OutputFileOptions
                    .Builder(
                            context.contentResolver,
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            contentValues
                    )
                    .build()
            else -> ImageCapture.OutputFileOptions
                    .Builder(File(outputPath))
                    .build()
        }

        flashViewFinder()

        val audio = getActivity().getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (audio.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
            MediaActionSound().play(MediaActionSound.SHUTTER_CLICK);
        }

        // Setup image capture listener which is triggered after photo has
        // been taken
        imageCapture?.takePicture(
                outputOptions, ContextCompat.getMainExecutor(getActivity()), object : ImageCapture.OnImageSavedCallback {
            override fun onError(ex: ImageCaptureException) {
                Log.e(TAG, "CameraView: Photo capture failed: ${ex.message}", ex)
                promise.reject("E_CAPTURE_FAILED", "takePicture failed: ${ex.message}")
            }

            override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                try {
                    val savedUri = output.savedUri.toString()
                    onPictureTaken(savedUri)
                    Log.d(TAG, "CameraView: Photo capture succeeded: $savedUri")

                    val imageInfo = Arguments.createMap()
                    imageInfo.putString("uri", savedUri)
                    imageInfo.putString("id", output.savedUri?.path)
                    imageInfo.putString("name", output.savedUri?.lastPathSegment)
                    // imageInfo.putInt("size", null)
                    imageInfo.putInt("width", width)
                    imageInfo.putInt("height", height)
                    imageInfo.putString("path", output.savedUri?.path)

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
    }

    private fun onBarcodeRead(barcodes: List<String>) {
        val event: WritableMap = Arguments.createMap()
        event.putArray("barcodes", Arguments.makeNativeArray(barcodes))
        currentContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
                id,
                "onBarcodeRead",
                event
        )
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

        val event: WritableMap = Arguments.createMap()
        event.putInt("orientation", remappedOrientation)
        currentContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
                id,
                "onOrientationChange",
                event
        )
    }

    private fun onPictureTaken(uri: String) {
        val event: WritableMap = Arguments.createMap()
        event.putString("uri", uri)
        currentContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(
                id,
                "onPictureTaken",
                event
        )
    }

    fun setFlashMode(mode: String?) {
        val imageCapture = imageCapture ?: return
        val camera = camera ?: return
        when (mode) {
            "torch" -> camera.cameraControl.enableTorch(true)
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

    fun setAutoFocus(mode: String = "on") {
        autoFocus = mode
        when(mode) {
            // "cancel" clear AF points and engages continuous auto-focus
            "on" -> camera?.cameraControl?.cancelFocusAndMetering()
            // 'off': Handled when you tap to focus
        }
    }

    fun setScanBarcode(enabled: Boolean) {
        val restartCamera = enabled != scanBarcode
        scanBarcode = enabled
        if (restartCamera) startCamera()
    }

    fun setType(type: String = "back") {
        val newLensType = when (type) {
            "front" -> CameraSelector.LENS_FACING_FRONT
            else -> CameraSelector.LENS_FACING_BACK
        }
        val restartCamera = lensType != newLensType
        lensType = newLensType
        if (restartCamera) startCamera()
    }

    fun setOutputPath(path: String) {
        outputPath = path
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
}