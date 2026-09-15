package com.rncamerakit

import android.Manifest
import android.app.Activity
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ThemedReactContext
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ReattachmentRegressionTest {
    private fun camera(): CKCamera {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        // Exercise view/executor ownership without opening physical camera hardware.
        shadowOf(RuntimeEnvironment.getApplication()).denyPermissions(Manifest.permission.CAMERA)
        val react = mock(ReactApplicationContext::class.java)
        `when`(react.currentActivity).thenReturn(activity)
        return CKCamera(ThemedReactContext(react, RuntimeEnvironment.getApplication(), "reattach", 1))
    }

    private fun executor(camera: CKCamera): ExecutorService =
        CKCamera::class.java.getDeclaredField("cameraExecutor").apply {
            isAccessible = true
        }.get(camera) as ExecutorService

    private fun attach(camera: CKCamera) = callback(camera, "onAttachedToWindow")
    private fun detach(camera: CKCamera) = callback(camera, "onDetachedFromWindow")
    private fun callback(camera: CKCamera, name: String) {
        CKCamera::class.java.getDeclaredMethod(name).apply {
            isAccessible = true
        }.invoke(camera)
    }

    @Test
    fun attachingWithAnActiveExecutorPreservesIt() {
        val camera = camera()
        val active = executor(camera)
        try {
            attach(camera)
            assertSame(active, executor(camera))
            active.submit {}.get(5, TimeUnit.SECONDS)
        } finally {
            detach(camera)
        }
    }

    @Test
    fun theSameViewAcceptsWorkAfterRepeatedDetachAndReattach() {
        val camera = camera()
        try {
            executor(camera).submit {}.get(5, TimeUnit.SECONDS)
            repeat(3) {
                val previous = executor(camera)
                detach(camera)
                assertTrue(previous.isShutdown)
                attach(camera)
                executor(camera).submit {}.get(5, TimeUnit.SECONDS)
                assertNotSame(previous, executor(camera))
                assertTrue(previous.isShutdown)
            }
        } finally {
            detach(camera)
        }
    }

    @Test
    fun reattachmentAcceptsWorkWhileThePreviousExecutorFinishes() {
        val camera = camera()
        val previous = executor(camera)
        val started = CountDownLatch(1)
        val release = CountDownLatch(1)
        val oldWork = previous.submit {
            started.countDown()
            assertTrue(release.await(5, TimeUnit.SECONDS))
        }
        try {
            assertTrue(started.await(5, TimeUnit.SECONDS))
            detach(camera)
            assertTrue(previous.isShutdown)
            assertFalse(previous.isTerminated)
            attach(camera)
            executor(camera).submit {}.get(5, TimeUnit.SECONDS)
            assertFalse(oldWork.isDone)
            release.countDown()
            oldWork.get(5, TimeUnit.SECONDS)
            assertTrue(previous.awaitTermination(5, TimeUnit.SECONDS))
        } finally {
            release.countDown()
            detach(camera)
        }
    }
}
