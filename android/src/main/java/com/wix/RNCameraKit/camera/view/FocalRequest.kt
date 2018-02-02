package com.wix.RNCameraKit.camera.view

/**
 * Created by minggong on 01/02/2018.
 */
data class FocalRequest(

        /**
         * The point where when user would like to focus.
         */
        val point: PointF,

        /**
         * Resolution of the preview
         */
        val previewResolution: Resolution
)
