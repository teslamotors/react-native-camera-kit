package com.rncamerakit

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.moduleinstall.InstallStatusListener
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallClient
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.android.gms.common.moduleinstall.ModuleInstallStatusUpdate
import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetector
import com.google.mlkit.vision.face.FaceDetectorOptions

data class FacePayload(
    val id: Int,
    val yaw: Double,
    val pitch: Double,
    val roll: Double,
    val boundsX: Double,
    val boundsY: Double,
    val boundsWidth: Double,
    val boundsHeight: Double,
)

class FaceAnalyzer(
    @Volatile var throttleMs: Long,
    context: Context,
    private val onInstallStatus: (state: String) -> Unit,
    private val onFaceDetected: (payloads: List<FacePayload>) -> Unit
) : ImageAnalysis.Analyzer {

    @Volatile private var detector: FaceDetector? = null
    @Volatile private var closed = false
    @Volatile private var moduleClient: ModuleInstallClient? = null
    @Volatile private var installListener: InstallStatusListener? = null

    private var lastEmitMs = 0L
    private var nextLocalId: Int = -1

    init {
        ensureModuleAndCreateDetector(context.applicationContext)
    }

    private fun createDetector() = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(MIN_FACE_SIZE)
            .enableTracking()
            .build()
    )

    private fun setDetectorIfAlive(d: FaceDetector) {
        if (closed) d.close() else detector = d
    }

    private fun ensureModuleAndCreateDetector(context: Context) {
        val status = GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context)
        if (status != ConnectionResult.SUCCESS) {
            Log.w(TAG, "Google Play Services unavailable (status=$status); face detection disabled.")
            onInstallStatus("unavailable")
            return
        }

        val newDetector = createDetector()
        val client = ModuleInstall.getClient(context).also { moduleClient = it }

        client.areModulesAvailable(newDetector)
            .addOnSuccessListener { response ->
                if (response.areModulesAvailable()) {
                    setDetectorIfAlive(newDetector)
                    onInstallStatus("ready")
                } else {
                    onInstallStatus("pending")
                    requestInstall(client, newDetector)
                }
            }
            .addOnFailureListener {
                onInstallStatus("pending")
                requestInstall(client, newDetector)
            }
    }

    private fun requestInstall(client: ModuleInstallClient, newDetector: FaceDetector) {
        val listener = InstallStatusListener { update ->
            when (update.installState) {
                ModuleInstallStatusUpdate.InstallState.STATE_DOWNLOADING ->
                    onInstallStatus("downloading")
                ModuleInstallStatusUpdate.InstallState.STATE_INSTALLING ->
                    onInstallStatus("installing")
                ModuleInstallStatusUpdate.InstallState.STATE_COMPLETED -> {
                    setDetectorIfAlive(newDetector)
                    onInstallStatus("ready")
                    unregisterInstallListener()
                }
                ModuleInstallStatusUpdate.InstallState.STATE_FAILED,
                ModuleInstallStatusUpdate.InstallState.STATE_CANCELED -> {
                    newDetector.close()
                    Log.w(TAG, "MLKit face module install ended in state=${update.installState}")
                    onInstallStatus("failed")
                    unregisterInstallListener()
                }
                else -> {}
            }
        }
        installListener = listener

        val request = ModuleInstallRequest.newBuilder()
            .addApi(newDetector)
            .setListener(listener)
            .build()

        client.installModules(request)
            .addOnSuccessListener { response ->
                if (response.areModulesAlreadyInstalled()) {
                    setDetectorIfAlive(newDetector)
                    onInstallStatus("ready")
                    unregisterInstallListener()
                }
            }
            .addOnFailureListener { e ->
                newDetector.close()
                Log.w(TAG, "MLKit face module install request failed: ${e.message}")
                onInstallStatus("failed")
                unregisterInstallListener()
            }
    }

    private fun unregisterInstallListener() {
        val l = installListener ?: return
        installListener = null
        moduleClient?.unregisterListener(l)
    }

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    fun analyzeWithoutClosing(image: ImageProxy): Task<*>? {
        val det = detector ?: return null
        val mediaImage = image.image ?: return null

        val now = System.currentTimeMillis()
        if (now - lastEmitMs < throttleMs) {
            return null
        }
        lastEmitMs = now

        val rotation = image.imageInfo.rotationDegrees
        val inputImage = InputImage.fromMediaImage(mediaImage, rotation)
        val width = if (rotation == 90 || rotation == 270) image.height else image.width
        val height = if (rotation == 90 || rotation == 270) image.width else image.height

        return det.process(inputImage)
            .addOnSuccessListener { faces -> dispatch(faces, width, height) }
    }

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val task = analyzeWithoutClosing(image)
        if (task == null) {
            image.close()
            return
        }
        task.addOnCompleteListener { image.close() }
    }

    private fun dispatch(faces: List<Face>, imgWidth: Int, imgHeight: Int) {
        val w = imgWidth.toDouble().coerceAtLeast(1.0)
        val h = imgHeight.toDouble().coerceAtLeast(1.0)
        val payloads = faces.map { face -> build(face, w, h) }
        onFaceDetected(payloads)
    }

    fun close() {
        closed = true
        unregisterInstallListener()
        detector?.close()
        detector = null
    }

    private fun build(face: Face, w: Double, h: Double): FacePayload {
        val box = face.boundingBox
        val id = face.trackingId ?: nextLocalId.also { nextLocalId-- }
        return FacePayload(
            id = id,
            yaw = face.headEulerAngleY.toDouble(),
            pitch = face.headEulerAngleX.toDouble(),
            roll = face.headEulerAngleZ.toDouble(),
            boundsX = box.left / w,
            boundsY = box.top / h,
            boundsWidth = box.width() / w,
            boundsHeight = box.height() / h,
        )
    }

    companion object {
        private const val TAG = "FaceAnalyzer"
        private const val MIN_FACE_SIZE = 0.15f
        const val DEFAULT_THROTTLE_MS = 100L
    }
}
