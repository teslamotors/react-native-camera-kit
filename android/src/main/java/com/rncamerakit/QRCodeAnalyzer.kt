package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

class QRCodeAnalyzer private constructor(
    private val onQRCodesDetected: (qrCodes: List<Barcode>, geometry: BarcodeFrameGeometry) -> Unit,
    private val scanThrottleDelay: Long,
    @Suppress("UNUSED_PARAMETER") frameCoordinates: Unit,
) : ImageAnalysis.Analyzer {
    // Preserve the existing native constructor and raw-buffer size callback.
    constructor(
        onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit,
        scanThrottleDelay: Long = 0L,
    ) : this({ codes, geometry -> onQRCodesDetected(codes, geometry.imageSize) }, scanThrottleDelay, Unit)

    companion object {
        internal fun withFrameGeometry(
            onDetected: (List<Barcode>, BarcodeFrameGeometry) -> Unit,
            scanThrottleDelay: Long,
        ) = QRCodeAnalyzer(onDetected, scanThrottleDelay, Unit)
    }

    // Time in milliseconds of the last time we dispatched detected barcodes
    private var lastBarcodeDetectedTime: Long = 0L

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    fun analyzeWithoutClosing(image: ImageProxy): Task<*>? = analyzeWithoutClosing(image, null)

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    internal fun analyzeWithoutClosing(
        image: ImageProxy,
        preview: BarcodePreviewGeometry?,
    ): Task<*>? {
        val mediaImage = image.image ?: return null

        val geometry = BarcodeFrameGeometry(
            image.width, image.height, image.imageInfo.rotationDegrees,
            image.imageInfo.sensorToBufferTransformMatrix, preview,
        )
        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

        val scanner = BarcodeScanning.getClient()
        return scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                // Throttle callback invocations based on scanThrottleDelay (ms)
                val now = System.currentTimeMillis()
                if (scanThrottleDelay > 0 && (now - lastBarcodeDetectedTime) < scanThrottleDelay) {
                    return@addOnSuccessListener
                }

                if (barcodes.isNotEmpty()) {
                    lastBarcodeDetectedTime = now
                    onQRCodesDetected(barcodes, geometry)
                }
            }
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
}
