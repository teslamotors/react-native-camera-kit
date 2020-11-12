package com.rncamerakit;

import androidx.annotation.Nullable;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.rncamerakit.camera.CameraModule;
import com.rncamerakit.camera.CameraViewManager;
import com.rncamerakit.camera.permission.CameraPermissionRequestCallback;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class RNCameraKitPackage implements ReactPackage {

    @Nullable private CameraPermissionRequestCallback cameraPermissionRequestCallback;

    public RNCameraKitPackage() {

    }

    public RNCameraKitPackage(CameraPermissionRequestCallback cameraPermissionRequestCallback) {
        this.cameraPermissionRequestCallback = cameraPermissionRequestCallback;
    }

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        List<NativeModule> modules = new ArrayList<>();

        CameraModule cameraModule = new CameraModule(reactContext);
        if (cameraPermissionRequestCallback != null) {
            cameraPermissionRequestCallback.setCameraModule(cameraModule);
        }
        modules.add(cameraModule);

        return modules;
    }

    // Deprecated RN 0.47
    public List<Class<? extends JavaScriptModule>> createJSModules() {
        return Collections.emptyList();
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        List<ViewManager> viewManagers = new ArrayList<>();
        viewManagers.add(new CameraViewManager());
        return viewManagers;
    }

}
