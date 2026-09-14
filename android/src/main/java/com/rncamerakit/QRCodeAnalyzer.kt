package com.rncamerakit

import android.annotation.SuppressLint
import android.util.Size
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

class QRCodeAnalyzer internal constructor(
    private val onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit,
    private val scanThrottleDelay: Long,
    private val scannerFactory: () -> BarcodeScanner,
) : ImageAnalysis.Analyzer, AutoCloseable {
    constructor(
        onQRCodesDetected: (qrCodes: List<Barcode>, imageSize: Size) -> Unit,
        scanThrottleDelay: Long = 0L,
    ) : this(onQRCodesDetected, scanThrottleDelay, { BarcodeScanning.getClient() })

    private enum class State { OPEN, CLOSING, CLOSED }
    private val lock = Any()
    private var state = State.OPEN
    private var scanner: BarcodeScanner? = null
    private var inFlight = 0

    // Time in milliseconds of the last time we dispatched detected barcodes
    private var lastBarcodeDetectedTime: Long = 0L

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    fun analyzeWithoutClosing(image: ImageProxy): Task<*>? = synchronized(lock) {
        if (state != State.OPEN) return null
        val mediaImage = image.image ?: return null
        val imageSize = Size(image.width, image.height)
        val inputImage = InputImage.fromMediaImage(mediaImage, image.imageInfo.rotationDegrees)
        val activeScanner = scanner ?: scannerFactory().also { scanner = it }
        // Register the consumer before process() can race with close().
        inFlight++
        val task = try {
            activeScanner.process(inputImage)
        } catch (e: Exception) {
            inFlight--
            closeIfIdle()
            throw e
        }
        task.addOnSuccessListener { barcodes ->
            synchronized(lock) {
                if (state != State.OPEN) return@addOnSuccessListener
                // Throttle callback invocations based on scanThrottleDelay (ms)
                val now = System.currentTimeMillis()
                if (scanThrottleDelay > 0 && (now - lastBarcodeDetectedTime) < scanThrottleDelay) {
                    return@addOnSuccessListener
                }

                if (barcodes.isNotEmpty()) {
                    lastBarcodeDetectedTime = now
                    onQRCodesDetected(barcodes, imageSize)
                }
            }
        }
        task.addOnCompleteListener {
            synchronized(lock) {
                inFlight--
                closeIfIdle()
            }
        }
        task
    }

    @SuppressLint("UnsafeExperimentalUsageError")
    @ExperimentalGetImage
    override fun analyze(image: ImageProxy) {
        analyzeSharedImage(image, ::analyzeWithoutClosing)
    }

    override fun close() = synchronized(lock) {
        if (state == State.OPEN) state = State.CLOSING
        closeIfIdle()
    }

    // All state transitions and outward callbacks are serialized by lock.
    private fun closeIfIdle() {
        if (state == State.CLOSING && inFlight == 0) {
            state = State.CLOSED
            val closingScanner = scanner
            scanner = null
            closingScanner?.close()
        }
    }
}
