package com.rncamerakit

import android.annotation.SuppressLint
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.media.Image
import android.media.ImageReader
import android.media.ImageWriter
import android.os.Debug
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.core.ImageInfo
import androidx.camera.core.ImageProxy
import androidx.camera.core.impl.TagBundle
import androidx.camera.core.impl.utils.ExifData
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** Real bundled ML Kit clients; authored Android YUV image; no camera/HAL claim. */
@RunWith(AndroidJUnit4::class)
@SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
class BarcodeNativeLifecycleTest {
    @Test
    fun repeatedGenerationsCloseClientsAndImagesExactlyOnce() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val ready = CountDownLatch(1)
        val reader = ImageReader.newInstance(320, 240, ImageFormat.YUV_420_888, 2)
        val writer = ImageWriter.newInstance(reader.surface, 2)
        reader.setOnImageAvailableListener({ ready.countDown() }, Handler(Looper.getMainLooper()))
        val writable = writer.dequeueInputImage()
        val qr = QRCodeWriter().encode("LIFECYCLE", BarcodeFormat.QR_CODE, 160, 160)
        for ((index, plane) in writable.planes.withIndex()) {
            val width = if (index == 0) 320 else 160
            val height = if (index == 0) 240 else 120
            for (y in 0 until height) for (x in 0 until width) {
                val value = if (index != 0) 128 else if (x in 80 until 240 && y in 40 until 200 && qr[x - 80, y - 40]) 0 else 255
                plane.buffer.put(y * plane.rowStride + x * plane.pixelStride, value.toByte())
            }
        }
        writer.queueInputImage(writable)
        assertTrue(ready.await(10, TimeUnit.SECONDS))
        val media = requireNotNull(reader.acquireNextImage())
        val created = AtomicInteger()
        val closed = AtomicInteger()
        val processed = AtomicInteger()
        val imageCloses = AtomicInteger()
        val events = AtomicInteger()
        fun report(generation: Int) {
            val memory = Debug.MemoryInfo().also { Debug.getMemoryInfo(it) }
            Log.i("CameraKitLifecycle", "generation=$generation created=${created.get()} closed=${closed.get()} processed=${processed.get()} imageCloses=${imageCloses.get()} events=${events.get()} nativeHeapBytes=${Debug.getNativeHeapAllocatedSize()} totalPssKb=${memory.totalPss} fixture=authored-yuv")
        }
        report(0)
        try {
            repeat(20) { generation ->
                var latest: Task<List<Barcode>>? = null
                val analyzer = QRCodeAnalyzer({ codes, _ ->
                    assertEquals(listOf("LIFECYCLE"), codes.map { it.rawValue })
                    events.incrementAndGet()
                }, 0) {
                    created.incrementAndGet()
                    val client = BarcodeScanning.getClient()
                    object : BarcodeScanner by client {
                        override fun process(image: InputImage): Task<List<Barcode>> {
                            processed.incrementAndGet()
                            return client.process(image).also { latest = it }
                        }
                        override fun close() {
                            closed.incrementAndGet()
                            client.close()
                        }
                    }
                }
                try {
                    repeat(3) { frame ->
                        val proxy = SceneImage(media, imageCloses)
                        instrumentation.runOnMainSync {
                            analyzer.analyze(proxy)
                            // Close before queued success callbacks can run for the final frame.
                            if (frame == 2) analyzer.close()
                        }
                        val done = CountDownLatch(1)
                        val task = requireNotNull(latest)
                        task.addOnCompleteListener { done.countDown() }
                        assertTrue(done.await(30, TimeUnit.SECONDS))
                        assertTrue("Real barcode inference failed: ${task.exception}", task.isSuccessful)
                        assertEquals(listOf("LIFECYCLE"), task.result.map { it.rawValue })
                        // The shared-task barrier schedules its own completion callback.
                        assertTrue("Shared image was not released", proxy.closed.await(5, TimeUnit.SECONDS))
                        assertEquals(1, proxy.closeCount)
                    }
                } finally {
                    analyzer.close()
                }
                assertEquals(generation + 1, created.get())
                assertEquals(generation + 1, closed.get())
                assertEquals((generation + 1) * 3, imageCloses.get())
                assertEquals((generation + 1) * 2, events.get())
                if ((generation + 1) % 5 == 0) report(generation + 1)
            }
            assertEquals(60, processed.get())
        } finally {
            media.close()
            writer.close()
            reader.close()
        }
    }

    private class SceneImage(private val media: Image, private val totalCloses: AtomicInteger) : ImageProxy {
        val closed = CountDownLatch(1)
        var closeCount = 0
        override fun close() { closeCount++; totalCloses.incrementAndGet(); closed.countDown() }
        // Media storage belongs to the fixture and is reused only after each task completes.
        override fun getImage(): Image = media
        override fun getWidth() = media.width
        override fun getHeight() = media.height
        override fun getFormat() = media.format
        override fun getCropRect() = Rect(0, 0, width, height)
        override fun setCropRect(rect: Rect?) = Unit
        override fun getPlanes(): Array<ImageProxy.PlaneProxy> = media.planes.map { plane ->
            object : ImageProxy.PlaneProxy {
                override fun getBuffer(): ByteBuffer = plane.buffer
                override fun getRowStride() = plane.rowStride
                override fun getPixelStride() = plane.pixelStride
            }
        }.toTypedArray()
        override fun getImageInfo(): ImageInfo = object : ImageInfo {
            override fun getRotationDegrees() = 0
            override fun getTimestamp() = media.timestamp
            override fun getTagBundle(): TagBundle = TagBundle.emptyBundle()
            override fun getSensorToBufferTransformMatrix() = Matrix()
            override fun populateExifData(builder: ExifData.Builder) = Unit
        }
    }
}
