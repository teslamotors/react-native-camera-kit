package com.rncamerakit

import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.RectF
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BarcodeCoordinateMapperTest {
    private fun matrix(vararg values: Float) = Matrix().apply { setValues(values) }

    private fun assertRect(expected: RectF, actual: RectF?) {
        assertNotNull(actual)
        assertEquals(expected.left, actual!!.left, 0.001f)
        assertEquals(expected.top, actual.top, 0.001f)
        assertEquals(expected.right, actual.right, 0.001f)
        assertEquals(expected.bottom, actual.bottom, 0.001f)
    }

    @Test
    fun mlKitRotationsAreUndoneExactlyOnce() {
        // Authored rotations of buffer box (600,300)-(700,400), not mapper output.
        val detections = listOf(
            0 to RectF(600f, 300f, 700f, 400f),
            90 to RectF(320f, 600f, 420f, 700f),
            180 to RectF(580f, 320f, 680f, 420f),
            270 to RectF(300f, 580f, 400f, 680f),
        )
        for ((rotation, bounds) in detections) {
            val geometry = BarcodeFrameGeometry(1280, 720, rotation, Matrix())
            assertRect(RectF(600f, 300f, 700f, 400f), geometry.mapBounds(bounds, Matrix()))
        }
    }

    @Test
    fun portraitPreviewAndFrontMirrorComeFromThePreviewMatrix() {
        val geometry = BarcodeFrameGeometry(1280, 720, 90, Matrix())
        val detection = RectF(320f, 600f, 420f, 700f)
        val back = matrix(0f, -1f, 720f, 1f, 0f, 0f, 0f, 0f, 1f)
        val front = matrix(0f, 1f, 0f, 1f, 0f, 0f, 0f, 0f, 1f)
        assertRect(RectF(320f, 600f, 420f, 700f), geometry.mapBounds(detection, back))
        assertRect(RectF(300f, 600f, 400f, 700f), geometry.mapBounds(detection, front))
    }

    @Test
    fun centerCropUsesOffsetsInsteadOfStretchingTheBuffer() {
        val geometry = BarcodeFrameGeometry(400, 200, 0, Matrix())
        val crop = matrix(1f, 0f, -100f, 0f, 1f, 0f, 0f, 0f, 1f)
        assertRect(RectF(0f, 50f, 100f, 150f), geometry.mapBounds(RectF(100f, 50f, 200f, 150f), crop))
    }

    @Test
    fun analysisSensorCropAndPreviewCropMayDiffer() {
        val sensorToBuffer = matrix(0.5f, 0f, -50f, 0f, 0.5f, -25f, 0f, 0f, 1f)
        val sensorToView = matrix(1f, 0f, -300f, 0f, 1f, -50f, 0f, 0f, 1f)
        val geometry = BarcodeFrameGeometry(400, 200, 0, sensorToBuffer)
        assertRect(RectF(0f, 50f, 100f, 100f), geometry.mapBounds(RectF(100f, 25f, 150f, 50f), sensorToView))
    }

    @Test
    fun fullBoxContainmentIncludesEdgesAndRejectsPartialAndOutsideBoxes() {
        val selection = BarcodePreviewGeometry(1, Matrix(), RectF(10f, 20f, 110f, 120f))
        val geometry = BarcodeFrameGeometry(200, 200, 0, Matrix())
        assertTrue(selection.contains(Rect(20, 30, 30, 40), geometry))
        assertTrue(selection.contains(Rect(10, 20, 110, 120), geometry))
        assertFalse(selection.contains(Rect(9, 30, 30, 40), geometry))
        assertFalse(selection.contains(Rect(120, 30, 130, 40), geometry))
    }

    @Test
    fun fractionalOutsideEdgeIsNotTruncatedIntoTheFrame() {
        val shifted = matrix(1f, 0f, 0.25f, 0f, 1f, 0f, 0f, 0f, 1f)
        val selection = BarcodePreviewGeometry(1, shifted, RectF(0f, 0f, 10f, 10f))
        val geometry = BarcodeFrameGeometry(20, 20, 0, Matrix())
        assertFalse(selection.contains(Rect(0, 0, 10, 10), geometry))
        val small = matrix(0.1f, 0f, 0f, 0f, 0.1f, 0f, 0f, 0f, 1f)
        assertTrue(BarcodePreviewGeometry(1, small, RectF(10f, 10f, 10.1f, 10.1f))
            .contains(Rect(100, 100, 101, 101), geometry))
    }

    @Test
    fun unavailableAndNoninvertibleTransformsCannotSelectAFramedBarcode() {
        val geometry = BarcodeFrameGeometry(200, 200, 0, Matrix())
        assertFalse(BarcodePreviewGeometry(1, null, RectF(0f, 0f, 200f, 200f))
            .contains(Rect(1, 1, 10, 10), geometry))
        val singular = BarcodeFrameGeometry(200, 200, 0, Matrix().apply { setScale(0f, 0f) })
        assertNull(singular.mapBounds(RectF(1f, 1f, 10f, 10f), Matrix()))
    }

    @Test
    fun snapshotsCopyMutableMatricesAndRectangles() {
        val transform = Matrix()
        val frame = RectF(0f, 0f, 100f, 100f)
        val selection = BarcodePreviewGeometry(1, transform, frame)
        val geometry = BarcodeFrameGeometry(200, 200, 0, transform)
        transform.setScale(0f, 0f)
        frame.setEmpty()
        assertTrue(selection.matches(BarcodePreviewGeometry(1, Matrix(), RectF(0f, 0f, 100f, 100f))))
        assertTrue(selection.contains(Rect(1, 1, 10, 10), geometry))
    }

    @Test
    fun rebindResizeAndFrameMovementInvalidateInFlightSelections() {
        val frame = RectF(0f, 0f, 100f, 100f)
        val selection = BarcodePreviewGeometry(1, Matrix(), frame)
        assertFalse(selection.matches(BarcodePreviewGeometry(2, Matrix(), frame)))
        assertFalse(selection.matches(BarcodePreviewGeometry(1, Matrix().apply { setScale(2f, 2f) }, frame)))
        assertFalse(selection.matches(BarcodePreviewGeometry(1, Matrix(), RectF(1f, 0f, 101f, 100f))))
        assertFalse(selection.matches(BarcodePreviewGeometry(1, null, null)))
    }
}
