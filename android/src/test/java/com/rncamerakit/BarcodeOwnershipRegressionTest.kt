package com.rncamerakit

import android.media.Image
import android.os.Looper
import androidx.camera.core.ImageInfo
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.TaskCompletionSource
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.mockito.stubbing.Answer
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.lang.reflect.InvocationTargetException

/** Shared regression harness also compiled against the unchanged baseline. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class BarcodeOwnershipRegressionTest {
    @Test
    fun repeatedFramesReuseOneOwnedScanner() {
        val media = mock(Image::class.java)
        val image = mock(ImageProxy::class.java)
        val info = mock(ImageInfo::class.java)
        `when`(image.image).thenReturn(media)
        `when`(image.imageInfo).thenReturn(info)
        `when`(image.width).thenReturn(128)
        `when`(image.height).thenReturn(96)
        val input = mock(InputImage::class.java)
        val scanner = mock(BarcodeScanner::class.java)
        val task = TaskCompletionSource<List<Barcode>>()
        `when`(scanner.process(input)).thenReturn(task.task)
        var factories = 0
        mockStatic(BarcodeScanning::class.java, Answer<Any?> {
            factories++
            scanner
        }).use {
            mockStatic(InputImage::class.java).use { inputs ->
                inputs.`when`<InputImage> { InputImage.fromMediaImage(media, 0) }.thenReturn(input)
                val analyzer = QRCodeAnalyzer({ _, _ -> }, 0)
                repeat(3) { analyzer.analyzeWithoutClosing(image) }
                assertEquals("One scanner belongs to the active analyzer generation", 1, factories)
                verify(scanner, times(3)).process(input)
            }
        }
    }

    @Test
    fun nullMediaDoesNotAllocateAScanner() {
        val image = mock(ImageProxy::class.java)
        mockStatic(BarcodeScanning::class.java).use { scanners ->
            assertNull(QRCodeAnalyzer({ _, _ -> }).analyzeWithoutClosing(image))
            scanners.verifyNoInteractions()
        }
    }

    private fun pipeline(barcode: QRCodeAnalyzer?, face: FaceAnalyzer?, image: ImageProxy) {
        // Invoke the actual callback installed in CKCamera's ImageAnalysis.
        val method = CKCamera::class.java.declaredMethods.single {
            it.parameterTypes.contentEquals(arrayOf(QRCodeAnalyzer::class.java, FaceAnalyzer::class.java, ImageProxy::class.java))
        }.apply { isAccessible = true }
        try {
            method.invoke(null, barcode, face, image)
        } catch (e: InvocationTargetException) {
            throw e.targetException
        }
    }

    @Test fun barcodeFinishingFirstKeepsTheSharedImageOpen() = completionOrder(true)
    @Test fun faceFinishingFirstKeepsTheSharedImageOpen() = completionOrder(false)

    private fun completionOrder(barcodeFirst: Boolean) {
        val image = mock(ImageProxy::class.java)
        val barcode = mock(QRCodeAnalyzer::class.java)
        val face = mock(FaceAnalyzer::class.java)
        val a = TaskCompletionSource<Void>()
        val b = TaskCompletionSource<Void>()
        `when`(barcode.analyzeWithoutClosing(image)).thenReturn(a.task)
        `when`(face.analyzeWithoutClosing(image)).thenReturn(b.task)
        pipeline(barcode, face, image)
        (if (barcodeFirst) a else b).setResult(null)
        shadowOf(Looper.getMainLooper()).idle()
        verify(image, never()).close()
        (if (barcodeFirst) b else a).setResult(null)
        shadowOf(Looper.getMainLooper()).idle()
        verify(image, times(1)).close()
    }

    @Test
    fun secondConsumerThrowStillClosesAfterTheFirstCompletes() {
        val image = mock(ImageProxy::class.java)
        val barcode = mock(QRCodeAnalyzer::class.java)
        val face = mock(FaceAnalyzer::class.java)
        val a = TaskCompletionSource<Void>()
        `when`(barcode.analyzeWithoutClosing(image)).thenReturn(a.task)
        `when`(face.analyzeWithoutClosing(image)).thenThrow(IllegalStateException("authored launch failure"))
        runCatching { pipeline(barcode, face, image) }
        verify(image, never()).close()
        a.setResult(null)
        shadowOf(Looper.getMainLooper()).idle()
        verify(image, times(1)).close()
    }

    @Test
    fun firstConsumerThrowStillRunsTheSecondAndClosesAfterIt() {
        val image = mock(ImageProxy::class.java)
        val barcode = mock(QRCodeAnalyzer::class.java)
        val face = mock(FaceAnalyzer::class.java)
        val b = TaskCompletionSource<Void>()
        `when`(barcode.analyzeWithoutClosing(image)).thenThrow(IllegalStateException("authored launch failure"))
        `when`(face.analyzeWithoutClosing(image)).thenReturn(b.task)
        runCatching { pipeline(barcode, face, image) }
        verify(face).analyzeWithoutClosing(image)
        verify(image, never()).close()
        b.setResult(null)
        shadowOf(Looper.getMainLooper()).idle()
        verify(image, times(1)).close()
    }

    @Test
    fun noConsumersCloseImmediately() {
        val image = mock(ImageProxy::class.java)
        pipeline(null, null, image)
        verify(image, times(1)).close()
    }
}
