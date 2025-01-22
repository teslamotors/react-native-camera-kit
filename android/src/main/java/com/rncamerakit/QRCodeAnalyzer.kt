package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

class QRCodeAnalyzer(
        private val onQRCodesDetected: (qrCodes: List<Pair<Barcode, Size>>) -> Unit
) : ImageAnalysis.Analyzer {
    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val mediaImage = image.image ?: return

        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

        val scanner = BarcodeScanning.getClient()
        scanner.process(inputImage)
                .addOnSuccessListener { barcodes ->
                    // Pair each barcode with the image dimensions
                    val result: List<Pair<Barcode, Size>> = barcodes.map { barcode -> barcode to Size(image.width, image.height) }
                    onQRCodesDetected(result)
                }
                .addOnCompleteListener {
                    image.close()
                }
    }
}
