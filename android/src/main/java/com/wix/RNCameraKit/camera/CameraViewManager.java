package com.wix.RNCameraKit.camera;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;

/**
 * Created by yedidyak on 04/07/2016.
 */
public class CameraViewManager extends SimpleViewManager<CameraView> {


    @Override
    public String getName() {
        return "CameraView";
    }

    @Override
    protected CameraView createViewInstance(ThemedReactContext reactContext) {
        return new CameraView(reactContext);
    }
}
