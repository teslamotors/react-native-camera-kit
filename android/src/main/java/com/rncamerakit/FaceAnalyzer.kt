package com.rncamerakit

import android.annotation.SuppressLint
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
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
    private val onFaceDetected: (payloads: List<FacePayload>) -> Unit
) : ImageAnalysis.Analyzer {

    private val detector = FaceDetection.getClient(
        FaceDetectorOptions.Builder()
            .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
            .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_NONE)
            .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_NONE)
            .setMinFaceSize(MIN_FACE_SIZE)
            .enableTracking()
            .build()
    )

    private var lastEmitMs = 0L
    private var nextLocalId: Int = -1

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val mediaImage = image.image
        if (mediaImage == null) {
            image.close()
            return
        }

        val now = System.currentTimeMillis()
        if (now - lastEmitMs < throttleMs) {
            image.close()
            return
        }
        lastEmitMs = now

        val rotation = image.imageInfo.rotationDegrees
        val inputImage = InputImage.fromMediaImage(mediaImage, rotation)
        val width = if (rotation == 90 || rotation == 270) image.height else image.width
        val height = if (rotation == 90 || rotation == 270) image.width else image.height

        detector.process(inputImage)
            .addOnSuccessListener { faces -> dispatch(faces, width, height) }
            .addOnCompleteListener { image.close() }
    }

    private fun dispatch(faces: List<Face>, imgWidth: Int, imgHeight: Int) {
        val w = imgWidth.toDouble().coerceAtLeast(1.0)
        val h = imgHeight.toDouble().coerceAtLeast(1.0)
        val payloads = faces.map { face -> build(face, w, h) }
        onFaceDetected(payloads)
    }

    fun close() {
        detector.close()
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
        private const val MIN_FACE_SIZE = 0.15f
        const val DEFAULT_THROTTLE_MS = 100L
    }
}
