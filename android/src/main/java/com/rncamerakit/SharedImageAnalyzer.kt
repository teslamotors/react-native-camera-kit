package com.rncamerakit

import android.util.Log
import androidx.camera.core.ImageProxy
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks

/** Every successfully launched consumer owns the image until its task settles. */
internal fun analyzeSharedImage(image: ImageProxy, vararg consumers: (ImageProxy) -> Task<*>?) {
    val tasks = mutableListOf<Task<*>>()
    for (consumer in consumers) {
        try {
            consumer(image)?.let { tasks.add(it) }
        } catch (e: Exception) {
            Log.w("CameraKit", "Image analyzer failed to start", e)
        }
    }
    if (tasks.isEmpty()) image.close()
    else Tasks.whenAllComplete(tasks).addOnCompleteListener { image.close() }
}
