package com.rncamerakit

import android.content.Context
import android.media.Image
import android.os.Looper
import android.view.WindowManager
import androidx.camera.core.ImageInfo
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerHelper
import com.google.android.gms.tasks.CancellationTokenSource
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BarcodeLifecycleTest {
    private class Fixture(val delay: Long = 0) : AutoCloseable {
        val media = mock(Image::class.java)
        val image = mock(ImageProxy::class.java)
        val info = mock(ImageInfo::class.java)
        val input = mock(InputImage::class.java)
        val scanner = mock(BarcodeScanner::class.java)
        val inputs = mockStatic(InputImage::class.java)
        val tasks = mutableListOf<TaskCompletionSource<List<Barcode>>>()
        var factories = 0
        var events = 0
        val analyzer = QRCodeAnalyzer({ _, size ->
            assertEquals(android.util.Size(128, 96), size)
            events++
        }, delay, { factories++; scanner })

        init {
            `when`(image.image).thenReturn(media)
            `when`(image.imageInfo).thenReturn(info)
            `when`(image.width).thenReturn(128)
            `when`(image.height).thenReturn(96)
            inputs.`when`<InputImage> { InputImage.fromMediaImage(media, 0) }.thenReturn(input)
            `when`(scanner.process(input)).thenAnswer {
                TaskCompletionSource<List<Barcode>>().also { tasks.add(it) }.task
            }
        }

        fun success(index: Int = 0, codes: Boolean = true) {
            tasks[index].setResult(if (codes) listOf(mock(Barcode::class.java)) else emptyList())
            idle()
        }

        fun idle() = shadowOf(Looper.getMainLooper()).idle()
        override fun close() {
            analyzer.close()
            inputs.close()
        }
    }

    @Test
    fun closeBeforeFirstFrameAllocatesNothingAndRejectsFurtherWork() = Fixture().use { f ->
        f.analyzer.close()
        f.analyzer.close()
        f.analyzer.analyze(f.image)
        assertEquals(0, f.factories)
        verify(f.image).close()
        verifyNoInteractions(f.scanner)
    }

    @Test
    fun closeWaitsForEveryPendingTaskAndSuppressesLateEvents() = Fixture().use { f ->
        repeat(2) { f.analyzer.analyzeWithoutClosing(f.image) }
        f.analyzer.close()
        f.analyzer.close()
        assertNull(f.analyzer.analyzeWithoutClosing(f.image))
        f.success(1)
        verify(f.scanner, never()).close()
        f.success(0)
        f.analyzer.close()
        assertEquals(0, f.events)
        assertEquals(1, f.factories)
        verify(f.scanner, times(1)).close()
        verify(f.image, never()).close() // analyzeWithoutClosing leaves image ownership with its caller.
    }

    @Test
    fun completedSuccessfulWorkClosesExactlyOnce() = Fixture().use { f ->
        f.analyzer.analyze(f.image)
        f.success()
        assertEquals(1, f.events)
        verify(f.image, times(1)).close()
        verify(f.scanner, never()).close()
        repeat(3) { f.analyzer.close() }
        verify(f.scanner, times(1)).close()
    }

    @Test
    fun failedWorkSettlesBothScannerAndImageOwnership() = Fixture().use { f ->
        f.analyzer.analyze(f.image)
        f.analyzer.close()
        f.tasks[0].setException(IllegalStateException("authored asynchronous failure"))
        f.idle()
        verify(f.scanner).close()
        verify(f.image).close()
        assertEquals(0, f.events)
    }

    @Test
    fun canceledWorkSettlesBothScannerAndImageOwnership() = Fixture().use { f ->
        val cancellation = CancellationTokenSource()
        val task = TaskCompletionSource<List<Barcode>>(cancellation.token)
        `when`(f.scanner.process(f.input)).thenReturn(task.task)
        f.analyzer.analyze(f.image)
        f.analyzer.close()
        cancellation.cancel()
        f.idle()
        verify(f.scanner).close()
        verify(f.image).close()
        assertEquals(0, f.events)
    }

    @Test
    fun synchronousProcessFailureDoesNotLeaveAnInFlightConsumer() = Fixture().use { f ->
        `when`(f.scanner.process(f.input)).thenThrow(IllegalStateException("authored launch failure"))
        f.analyzer.analyze(f.image)
        f.analyzer.close()
        verify(f.image).close()
        verify(f.scanner).close()
    }

    @Test
    fun inputSetupFailureClosesTheImageWithoutCreatingAScanner() = Fixture().use { f ->
        f.inputs.`when`<InputImage> { InputImage.fromMediaImage(f.media, 0) }
            .thenThrow(IllegalArgumentException("authored unsupported image"))
        f.analyzer.analyze(f.image)
        f.analyzer.close()
        assertEquals(0, f.factories)
        verify(f.image).close()
        verifyNoInteractions(f.scanner)
    }

    @Test
    fun scannerFactoryFailureClosesTheImage() = Fixture().use { f ->
        val analyzer = QRCodeAnalyzer({ _, _ -> }, 0) { throw IllegalStateException("authored factory failure") }
        analyzer.analyze(f.image)
        analyzer.close()
        verify(f.image).close()
    }

    @Test
    fun eventThrottleDoesNotBecomeAnInferenceThrottle() = Fixture(60_000).use { f ->
        f.analyzer.analyzeWithoutClosing(f.image)
        f.success(0)
        f.analyzer.analyzeWithoutClosing(f.image)
        f.success(1)
        assertEquals(1, f.events)
        verify(f.scanner, times(2)).process(f.input)
        assertEquals(1, f.factories)
    }

    @Test
    fun closeRacingWithProcessWaitsUntilTheReturnedTaskSettles() = Fixture().use { f ->
        val executor = Executors.newSingleThreadExecutor()
        val attemptingClose = CountDownLatch(1)
        lateinit var closing: Future<*>
        val pending = TaskCompletionSource<List<Barcode>>()
        `when`(f.scanner.process(f.input)).thenAnswer {
            closing = executor.submit {
                attemptingClose.countDown()
                f.analyzer.close()
            }
            assertTrue(attemptingClose.await(5, TimeUnit.SECONDS))
            verify(f.scanner, never()).close()
            pending.task
        }
        try {
            f.analyzer.analyzeWithoutClosing(f.image)
            closing.get(5, TimeUnit.SECONDS)
            verify(f.scanner, never()).close()
            pending.setResult(listOf(mock(Barcode::class.java)))
            f.idle()
            verify(f.scanner).close()
            assertEquals(0, f.events)
        } finally {
            executor.shutdownNow()
        }
    }

    @Test
    fun closingOneGenerationDoesNotCloseItsReplacement() = Fixture().use { f ->
        f.analyzer.analyzeWithoutClosing(f.image)
        f.analyzer.close()
        val replacementScanner = mock(BarcodeScanner::class.java)
        val pending = TaskCompletionSource<List<Barcode>>()
        `when`(replacementScanner.process(f.input)).thenReturn(pending.task)
        var events = 0
        val replacement = QRCodeAnalyzer({ _, _ -> events++ }, 0) { replacementScanner }
        replacement.analyzeWithoutClosing(f.image)
        f.success()
        verify(f.scanner).close()
        verify(replacementScanner, never()).close()
        pending.setResult(listOf(mock(Barcode::class.java)))
        f.idle()
        assertEquals(0, f.events)
        assertEquals(1, events)
        replacement.close()
        verify(replacementScanner).close()
    }

    private fun camera(): CKCamera {
        val context = ThemedReactContext(mock(ReactApplicationContext::class.java), RuntimeEnvironment.getApplication(), "lifecycle", 1)
        return CKCamera(context)
    }

    private fun set(camera: CKCamera, field: String, value: Any?) {
        CKCamera::class.java.getDeclaredField(field).apply { isAccessible = true }.set(camera, value)
    }

    @Test
    fun cameraDetachClosesAndReleasesItsOwnedAnalyzer() {
        val camera = camera()
        val analyzer = mock(QRCodeAnalyzer::class.java)
        set(camera, "barcodeAnalyzer", analyzer)
        repeat(2) {
            CKCamera::class.java.getDeclaredMethod("onDetachedFromWindow").apply { isAccessible = true }.invoke(camera)
        }
        verify(analyzer, times(1)).close()
        assertNull(CKCamera::class.java.getDeclaredField("barcodeAnalyzer").apply { isAccessible = true }.get(camera))
    }

    @Test fun cameraRebindReplacesTheOwnedGeneration() = rebind(true)
    @Test fun disablingBarcodeScanningClosesTheOwnedGeneration() = rebind(false)

    private fun rebind(enabled: Boolean) {
        val camera = camera()
        val old = mock(QRCodeAnalyzer::class.java)
        val view = spy(PreviewView(camera.context)).apply { layout(0, 0, 1280, 720) }
        val display = (camera.context.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay
        `when`(view.display).thenReturn(display)
        set(camera, "viewFinder", view)
        set(camera, "cameraProvider", mock(ProcessCameraProvider::class.java))
        set(camera, "barcodeAnalyzer", old)
        set(camera, "scanBarcode", enabled)
        // No camera is bound in this unit fixture; its error event is a bridge boundary.
        mockStatic(UIManagerHelper::class.java).use {
            CKCamera::class.java.getDeclaredMethod("bindCameraUseCases").apply { isAccessible = true }.invoke(camera)
        }
        verify(old).close()
        val replacement = CKCamera::class.java.getDeclaredField("barcodeAnalyzer").apply { isAccessible = true }.get(camera)
        if (enabled) assertTrue(replacement is QRCodeAnalyzer && replacement !== old) else assertNull(replacement)
        (replacement as? QRCodeAnalyzer)?.close()
    }
}
