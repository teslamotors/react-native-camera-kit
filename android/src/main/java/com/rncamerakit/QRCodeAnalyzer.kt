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

class QRCodeAnalyzer (
    private val onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit,
    private val scanThrottleDelay: Long = 0L
) : ImageAnalysis.Analyzer {
    // Time in milliseconds of the last time we dispatched detected barcodes
    private var lastBarcodeDetectedTime: Long = 0L

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    fun analyzeWithoutClosing(image: ImageProxy): Task<*>? {
        val mediaImage = image.image ?: return null

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
                    onQRCodesDetected(barcodes, Size(image.width, image.height))
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
