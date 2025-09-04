package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
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
    override fun analyze(image: ImageProxy) {
        val mediaImage = image.image ?: return

        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

        val scanner = BarcodeScanning.getClient()
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                // Throttle callback invocations based on scanThrottleDelay (ms)
                val now = System.currentTimeMillis()
                if (scanThrottleDelay > 0 && (now - lastBarcodeDetectedTime) < scanThrottleDelay) {
                    return@addOnSuccessListener
                }

                val strBarcodes = mutableListOf<Barcode>()
                barcodes.forEach { barcode ->
                    strBarcodes.add(barcode ?: return@forEach)
                }

                if (strBarcodes.isNotEmpty()) {
                    lastBarcodeDetectedTime = now
                    onQRCodesDetected(strBarcodes, Size(image.width, image.height))
                }
            }
            .addOnCompleteListener {
                image.close()
            }
    }
}
