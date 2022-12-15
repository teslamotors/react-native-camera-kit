package com.rncamerakit

import android.annotation.SuppressLint
import android.graphics.Rect
import android.graphics.RectF
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import com.rncamerakit.barcode.BarcodeFrame

class QRCodeAnalyzer(
    private val barcodeFrame: BarcodeFrame,
    private val previewViewWidth: Float,
    private val previewViewHeight: Float,
    private val onQRCodesDetected: (qrCodes: List<String>) -> Unit
) : ImageAnalysis.Analyzer {

    private var scaleX = 1f
    private var scaleY = 1f

    private fun translateX(x: Float) = x * scaleX
    private fun translateY(y: Float) = y * scaleY

    private fun adjustBoundingRect(rect: Rect) = RectF(
        translateX(rect.left.toFloat()),
        translateY(rect.top.toFloat()),
        translateX(rect.right.toFloat()),
        translateY(rect.bottom.toFloat())
    )

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        val inputImage = InputImage.fromMediaImage(image.image!!, image.imageInfo.rotationDegrees)
        val img = image.image
        if (img != null) {
            scaleX = previewViewWidth / img.height.toFloat()
            scaleY = previewViewHeight / img.width.toFloat()
            val scanner = BarcodeScanning.getClient()
            scanner.process(inputImage)
                .addOnSuccessListener { barcodes ->
                    val strBarcodes = mutableListOf<String>()
                    barcodes.forEach { barcode ->
                        barcode.boundingBox?.let { rect ->
                            if (barcodeFrame.isQRInsideFrame(adjustBoundingRect(rect))) {
                                strBarcodes.add(barcode.rawValue ?: return@forEach)
                            }
                        }
                    }
                    onQRCodesDetected(strBarcodes)
                }
                .addOnCompleteListener {
                    image.close()
                }
        }

    }
}