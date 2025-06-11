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
    private val scanThrottleDelay: () -> Int,
    private val onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit
) : ImageAnalysis.Analyzer {
    private var lastScanTime: Long = 0

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val currentTime = System.currentTimeMillis()
        val delay = scanThrottleDelay();
        if (currentTime - lastScanTime < delay) {
            image.close()
            return
        }
        lastScanTime = currentTime

        val mediaImage = image.image ?: return

        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

        val scanner = BarcodeScanning.getClient()
        scanner.process(inputImage)
            .addOnSuccessListener { barcodes ->
                val strBarcodes = mutableListOf<Barcode>()
                barcodes.forEach { barcode ->
                    strBarcodes.add(barcode ?: return@forEach)
                }
                onQRCodesDetected(strBarcodes, Size(image.width, image.height))
            }
            .addOnCompleteListener {
                image.close()
            }
    }
}
