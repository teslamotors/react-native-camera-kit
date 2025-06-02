package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.barcode.BarcodeScannerOptions

class QRCodeAnalyzer (
    private val onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit
) : ImageAnalysis.Analyzer {
    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val mediaImage = image.image ?: return

        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)

        val options = BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build()
                
        val scanner = BarcodeScanning.getClient(options)
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
