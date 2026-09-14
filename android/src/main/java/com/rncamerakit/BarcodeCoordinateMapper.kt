package com.rncamerakit

import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import android.util.Size

/** Immutable snapshot of the visible selection at frame submission. */
internal class BarcodePreviewGeometry(
    private val generation: Long,
    sensorToFrame: Matrix?,
    frame: RectF?,
) {
    private val sensorToFrame = sensorToFrame?.let { Matrix(it) }
    private val frame = frame?.let { RectF(it) }
    val hasFrame: Boolean get() = frame != null

    fun matches(other: BarcodePreviewGeometry): Boolean =
        generation == other.generation && sensorToFrame == other.sensorToFrame && frame == other.frame

    fun contains(bounds: Rect, image: BarcodeFrameGeometry): Boolean {
        val selection = frame ?: return true
        val transform = sensorToFrame ?: return false
        val mapped = image.mapBounds(RectF(bounds), transform) ?: return false
        return selection.contains(mapped)
    }
}

/** ML Kit reports boxes after applying InputImage's rotation, in the full image.
 * Its coordinates do not start at ImageProxy.cropRect's top-left. Map back to
 * the sensor, then through PreviewView's crop/scale/mirror transform exactly once.
 * The sensor matrices do not require changing ImageCapture's ViewPort or crop.
 */
internal class BarcodeFrameGeometry(
    private val width: Int,
    private val height: Int,
    private val rotationDegrees: Int,
    sensorToBuffer: Matrix,
    val preview: BarcodePreviewGeometry? = null,
) {
    private val sensorToBuffer = Matrix(sensorToBuffer)
    val imageSize = Size(width, height)

    fun mapBounds(bounds: RectF, sensorToView: Matrix): RectF? {
        if (width <= 0 || height <= 0 || rotationDegrees !in listOf(0, 90, 180, 270)) return null
        val bufferToDetection = Matrix().apply { setRotate(rotationDegrees.toFloat()) }
        val rotatedBuffer = RectF(0f, 0f, width.toFloat(), height.toFloat())
        bufferToDetection.mapRect(rotatedBuffer)
        bufferToDetection.postTranslate(-rotatedBuffer.left, -rotatedBuffer.top)
        val sensorToDetection = Matrix().apply {
            setConcat(bufferToDetection, sensorToBuffer)
        }
        val detectionToSensor = Matrix()
        if (!sensorToDetection.invert(detectionToSensor)) return null
        val detectionToView = Matrix().apply { setConcat(sensorToView, detectionToSensor) }
        return RectF(bounds).also { detectionToView.mapRect(it) }
    }
}
