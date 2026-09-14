package com.rncamerakit

import android.graphics.Matrix
import android.graphics.Rect
import androidx.camera.view.PreviewView
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.events.EventDispatcher
import com.google.mlkit.vision.barcode.common.Barcode
import com.rncamerakit.barcode.BarcodeFrame
import com.rncamerakit.events.ReadCodeEvent
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.mockito.stubbing.Answer
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BarcodeSelectionTest {
    private class Fixture {
        val context = ThemedReactContext(
            mock(ReactApplicationContext::class.java), RuntimeEnvironment.getApplication(), "selection", 1,
        )
        val camera = CKCamera(context).apply { id = 42 }
        val preview = spy(PreviewView(context)).apply { layout(0, 0, 1280, 720) }
        val frame = BarcodeFrame(context).apply { frameRect = Rect(400, 180, 880, 540) }

        init {
            set("viewFinder", preview)
            set("barcodeFrame", frame)
            `when`(preview.sensorToViewTransform).thenReturn(Matrix())
        }

        fun set(name: String, value: Any?) {
            CKCamera::class.java.getDeclaredField(name).apply { isAccessible = true }.set(camera, value)
        }

        fun geometry() = BarcodeFrameGeometry(1280, 720, 0, Matrix(), camera.snapshotBarcodePreview())

        fun emit(codes: List<Barcode>, geometry: BarcodeFrameGeometry = geometry()): List<String?> {
            val values = mutableListOf<String?>()
            val dispatcher = mock(EventDispatcher::class.java, Answer<Any?> { invocation ->
                if (invocation.method.name == "dispatchEvent") {
                    val event = invocation.arguments[0] as ReadCodeEvent
                    assertEquals("topReadCode", event.eventName)
                    values.add(ReadCodeEvent::class.java.getDeclaredField("codeStringValue").apply {
                        isAccessible = true
                    }.get(event) as String?)
                }
                null
            })
            mockStatic(UIManagerHelper::class.java).use { ui ->
                ui.`when`<Int> { UIManagerHelper.getSurfaceId(context) }.thenReturn(1)
                ui.`when`<EventDispatcher> {
                    UIManagerHelper.getEventDispatcherForReactTag(context, camera.id)
                }.thenReturn(dispatcher)
                camera.onBarcodesDetected(codes, geometry)
            }
            return values
        }
    }

    private fun barcode(value: String, bounds: Rect?, format: Int = Barcode.FORMAT_QR_CODE): Barcode {
        val barcode = mock(Barcode::class.java)
        `when`(barcode.rawValue).thenReturn(value)
        `when`(barcode.boundingBox).thenReturn(bounds)
        `when`(barcode.format).thenReturn(format)
        return barcode
    }

    private fun scene() = listOf(
        barcode("INSIDE", Rect(600, 300, 700, 400)),
        barcode("OUTSIDE", Rect(300, 400, 390, 500)),
    )

    @Test
    fun zeroRotationEmitsInsideBarcodeOnly() {
        assertEquals(listOf("INSIDE"), Fixture().emit(scene()))
    }

    @Test
    fun unavailablePreviewTransformDefersFramedEvents() {
        val fixture = Fixture()
        `when`(fixture.preview.sensorToViewTransform).thenReturn(null)
        assertEquals(emptyList<String>(), fixture.emit(scene()))
    }

    @Test
    fun noFramePreservesDetectionsWithoutBoundingBoxes() {
        val fixture = Fixture()
        fixture.set("barcodeFrame", null)
        `when`(fixture.preview.sensorToViewTransform).thenReturn(null)
        assertEquals(listOf("UNFRAMED"), fixture.emit(listOf(barcode("UNFRAMED", null))))
    }

    @Test
    fun formatFilterStillPrecedesTheFirstEmittedEvent() {
        val fixture = Fixture()
        fixture.set("barcodeFrame", null)
        fixture.set("allowedBarcodeTypes", arrayOf(CodeFormat.QR))
        assertEquals(listOf("QR_ONLY"), fixture.emit(listOf(
            barcode("CODE128", null, Barcode.FORMAT_CODE_128), barcode("QR_ONLY", null),
        )))
    }

    @Test
    fun lateDetectionCannotUseANewPreviewTransform() {
        val fixture = Fixture()
        val submitted = fixture.geometry()
        `when`(fixture.preview.sensorToViewTransform).thenReturn(Matrix().apply { setScale(2f, 2f) })
        assertEquals(emptyList<String>(), fixture.emit(scene(), submitted))
    }

    @Test
    fun cameraSwitchOrUnmountInvalidatesTheSubmittedGeneration() {
        val fixture = Fixture()
        val submitted = fixture.geometry()
        fixture.set("barcodeBindingGeneration", 1L)
        assertEquals(emptyList<String>(), fixture.emit(scene(), submitted))
    }

    @Test
    fun previewAndFrameOffsetsAreIncluded() {
        val fixture = Fixture()
        fixture.preview.layout(20, 40, 1300, 760)
        fixture.frame.layout(5, 7, 1285, 727)
        fixture.frame.frameRect = Rect(615, 333, 715, 433)
        assertEquals(listOf("INSIDE"), fixture.emit(scene()))
    }

    @Test
    fun movingTheScanFrameInvalidatesAPendingSelection() {
        val fixture = Fixture()
        val submitted = fixture.geometry()
        fixture.frame.frameRect = Rect(500, 200, 900, 600)
        assertEquals(emptyList<String>(), fixture.emit(scene(), submitted))
    }
}
