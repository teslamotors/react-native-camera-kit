package com.wix.RNCameraKit.torch

import android.content.Context
import android.hardware.Camera
import android.hardware.camera2.CameraManager
import android.os.Build
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class TorchModule(private val myReactContext: ReactApplicationContext)
    : ReactContextBaseJavaModule(myReactContext) {
    private var isTorchOn: Boolean? = false
    private var camera: Camera? = null

    override fun getName(): String {
        return "CKTorch"
    }

    @ReactMethod
    fun switchState(newState: Boolean?, successCallback: Callback, failureCallback: Callback) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val cameraManager = this.myReactContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            try {
                val cameraId = cameraManager.cameraIdList[0]
                cameraManager.setTorchMode(cameraId, newState!!)
                successCallback.invoke(true)
            } catch (e: Exception) {
                val errorMessage = e.message
                failureCallback.invoke("Error: $errorMessage")
            }

        } else {
            val params: Camera.Parameters

            if (!isTorchOn!!) {
                camera = Camera.open()
                params = camera!!.parameters
                params.flashMode = Camera.Parameters.FLASH_MODE_TORCH
                camera!!.parameters = params
                camera!!.startPreview()
                isTorchOn = true
            } else {
                params = camera!!.parameters
                params.flashMode = Camera.Parameters.FLASH_MODE_OFF

                camera!!.parameters = params
                camera!!.stopPreview()
                camera!!.release()
                isTorchOn = false
            }
        }
    }
}