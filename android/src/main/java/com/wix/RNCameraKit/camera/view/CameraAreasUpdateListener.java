package com.wix.RNCameraKit.camera.view;

import android.hardware.Camera;

import java.util.List;

/**
 * Created by minggong on 01/02/2018.
 */

public interface CameraAreasUpdateListener {
    void onCameraAreasUpdated(List<Camera.Area> areas);
}
