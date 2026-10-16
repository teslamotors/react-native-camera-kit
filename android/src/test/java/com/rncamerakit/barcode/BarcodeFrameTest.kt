package com.rncamerakit.barcode

import android.graphics.Rect
import android.util.Size
import android.view.View
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "mdpi")
class BarcodeFrameTest {
    // Square, portrait/landscape 4:3, and portrait/landscape 16:9.
    private val previewSizes = listOf(
        Size(800, 800), Size(600, 800), Size(800, 600),
        Size(450, 800), Size(800, 450),
    )

    @Test
    fun directLayoutCentersTheFrameWithoutMeasurement() {
        for (size in previewSizes) {
            val frame = newFrame()
            // CKCamera.setShowFrame lays out a new overlay directly.
            frame.layout(0, 0, size.width, size.height)
            assertCentered(frame, size)
        }
    }

    @Test
    fun measuredLayoutPreservesTheSameFrameBounds() {
        for (size in previewSizes) {
            val frame = newFrame()
            frame.measure(exactly(size.width), exactly(size.height))
            frame.layout(0, 0, size.width, size.height)
            assertCentered(frame, size)
        }
    }

    @Test
    fun layoutResizeUpdatesTheFrameEvenWhenMeasuredSizeIsStale() {
        val frame = newFrame()
        frame.measure(exactly(600), exactly(800))
        frame.layout(0, 0, 600, 800)
        frame.layout(0, 0, 800, 600)
        assertEquals(600, frame.measuredWidth)
        assertCentered(frame, Size(800, 600))
    }

    @Test
    fun customFrameSizeUsesTheCurrentLayoutBounds() {
        val frame = newFrame()
        frame.layout(0, 0, 800, 600)
        frame.setFrameSize(Size(200, 100))
        assertEquals(Rect(300, 250, 500, 350), frame.frameRect)
        frame.setFrameSize(null)
        assertCentered(frame, Size(800, 600))
    }

    private fun newFrame() = BarcodeFrame(RuntimeEnvironment.getApplication()).apply {
        setFrameSize(Size(300, 150))
    }

    private fun assertCentered(frame: BarcodeFrame, size: Size) {
        assertEquals(
            "Frame bounds after layout to $size",
            Rect(size.width / 2 - 150, size.height / 2 - 75, size.width / 2 + 150, size.height / 2 + 75),
            frame.frameRect,
        )
    }

    private fun exactly(size: Int) = View.MeasureSpec.makeMeasureSpec(size, View.MeasureSpec.EXACTLY)
}
