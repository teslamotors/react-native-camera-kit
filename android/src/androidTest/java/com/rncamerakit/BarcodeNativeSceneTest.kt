package com.rncamerakit

import android.annotation.SuppressLint
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.media.Image
import android.media.ImageReader
import android.media.ImageWriter
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.Size
import androidx.camera.core.ImageInfo
import androidx.camera.core.ImageProxy
import androidx.camera.core.impl.TagBundle
import androidx.camera.core.impl.utils.ExifData
import androidx.camera.view.PreviewView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.facebook.react.uimanager.ThemedReactContext
import com.google.android.gms.tasks.Tasks
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import com.rncamerakit.barcode.BarcodeFrame
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Real Android media images -> bundled ML Kit -> CKCamera -> native event IDs.
 * Sensor/preview transforms are authored fixtures, not sensor/HAL measurements.
 * No JavaScript, physical camera, scanner mock or screenshot oracle is used.
 */
@RunWith(AndroidJUnit4::class)
@SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
class BarcodeNativeSceneTest {
    @Test
    fun authoredTwoCodeSceneSelectsOnlyInsideAcrossAllMlKitRotations() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val ready = CountDownLatch(1)
        val reader = ImageReader.newInstance(1280, 720, ImageFormat.YUV_420_888, 2)
        val writer = ImageWriter.newInstance(reader.surface, 2)
        reader.setOnImageAvailableListener({ ready.countDown() }, Handler(Looper.getMainLooper()))
        val image = writer.dequeueInputImage()
        val pixels = ByteArray(1280 * 720) { 255.toByte() }
        fun code(value: String, x: Int, y: Int, size: Int) {
            val bits = QRCodeWriter().encode(value, BarcodeFormat.QR_CODE, size, size,
                mapOf(EncodeHintType.MARGIN to 1))
            for (row in 0 until size) for (column in 0 until size) {
                pixels[(y + row) * 1280 + x + column] = if (bits[column, row]) 0 else 255.toByte()
            }
        }
        code("INSIDE", 600, 300, 100)
        code("OUTSIDE", 300, 400, 90)
        for ((index, plane) in image.planes.withIndex()) {
            val width = if (index == 0) 1280 else 640
            val height = if (index == 0) 720 else 360
            for (y in 0 until height) for (x in 0 until width) {
                plane.buffer.put(y * plane.rowStride + x * plane.pixelStride,
                    if (index == 0) pixels[y * 1280 + x] else 128.toByte())
            }
        }
        writer.queueInputImage(image)
        assertTrue("Authored Android image did not arrive", ready.await(10, TimeUnit.SECONDS))
        val media = requireNotNull(reader.acquireNextImage())
        try {
            for (rotation in listOf(0, 90, 180, 270)) {
                lateinit var react: RecordingReactContext
                lateinit var camera: CKCamera
                lateinit var preview: BarcodePreviewGeometry
                instrumentation.runOnMainSync {
                    react = RecordingReactContext(instrumentation.targetContext)
                    val context = ThemedReactContext(react, instrumentation.targetContext, "native-scene", 1)
                    camera = CKCamera(context).apply { id = 42 }
                    val fixturePreview = PreviewView(context).apply { layout(0, 0, 1280, 720) }
                    // Seed CameraX's real preview transform with authored surface metadata.
                    val transform = PreviewView::class.java.getDeclaredField("mPreviewTransform")
                        .apply { isAccessible = true }.get(fixturePreview)
                    for ((name, value) in mapOf(
                        "mResolution" to Size(1280, 720),
                        "mSurfaceCropRect" to Rect(0, 0, 1280, 720),
                        "mSensorToBufferTransform" to Matrix(),
                    )) {
                        transform.javaClass.getDeclaredField(name).apply { isAccessible = true }
                            .set(transform, value)
                    }
                    assertTrue(requireNotNull(fixturePreview.sensorToViewTransform).isIdentity)
                    val frame = BarcodeFrame(context).apply { frameRect = Rect(400, 180, 880, 540) }
                    CKCamera::class.java.getDeclaredField("viewFinder").apply { isAccessible = true }
                        .set(camera, fixturePreview)
                    CKCamera::class.java.getDeclaredField("barcodeFrame").apply { isAccessible = true }
                        .set(camera, frame)
                    preview = camera.snapshotBarcodePreview()
                }
                val callback = CountDownLatch(1)
                val decoded = mutableSetOf<String?>()
                val analyzer = QRCodeAnalyzer.withFrameGeometry({ barcodes, geometry ->
                    decoded.addAll(barcodes.map { it.rawValue })
                    camera.onBarcodesDetected(barcodes, geometry)
                    callback.countDown()
                }, 0)
                val task = requireNotNull(analyzer.analyzeWithoutClosing(SceneImage(media, rotation), preview))
                Tasks.await(task, 30, TimeUnit.SECONDS)
                assertTrue("Native ML Kit success callback did not arrive", callback.await(10, TimeUnit.SECONDS))
                assertEquals(setOf("INSIDE", "OUTSIDE"), decoded)
                assertEquals(listOf("INSIDE"), react.values)
                Log.i("CameraKitScene", "rotation=$rotation buffer=1280x720 crop=(0,0,1280,720) decoded=$decoded emitted=${react.values} transforms=authored")
            }
        } finally {
            media.close()
            writer.close()
            reader.close()
        }
    }

    private class SceneImage(private val media: Image, private val rotation: Int) : ImageProxy {
        override fun getImage(): Image = media
        override fun getWidth() = media.width
        override fun getHeight() = media.height
        override fun getFormat() = media.format
        override fun getCropRect() = Rect(0, 0, width, height)
        override fun setCropRect(rect: Rect?) = Unit
        override fun close() = Unit // The fixture owns and reuses this completed image.
        override fun getPlanes(): Array<ImageProxy.PlaneProxy> = media.planes.map { plane ->
            object : ImageProxy.PlaneProxy {
                override fun getBuffer(): ByteBuffer = plane.buffer
                override fun getRowStride() = plane.rowStride
                override fun getPixelStride() = plane.pixelStride
            }
        }.toTypedArray()
        override fun getImageInfo(): ImageInfo = object : ImageInfo {
            override fun getRotationDegrees() = rotation
            override fun getTimestamp() = media.timestamp
            override fun getTagBundle(): TagBundle = TagBundle.emptyBundle()
            override fun getSensorToBufferTransformMatrix() = Matrix()
            override fun populateExifData(builder: ExifData.Builder) = Unit
        }
    }
}
