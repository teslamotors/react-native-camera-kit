package com.wix.RNCameraKit;

import android.support.annotation.Nullable;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.wix.RNCameraKit.camera.CameraModule;
import com.wix.RNCameraKit.camera.CameraViewManager;
import com.wix.RNCameraKit.camera.permission.CameraPermissionRequestCallback;
import com.wix.RNCameraKit.gallery.GalleryViewManager;
import com.wix.RNCameraKit.gallery.NativeGalleryModule;
import com.wix.RNCameraKit.gallery.permission.StoragePermissionRequestCallback;
import com.wix.RNCameraKit.torch.TorchModule;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class RNCameraKitPackage implements ReactPackage {

    @Nullable private CameraPermissionRequestCallback cameraPermissionRequestCallback;
    @Nullable private StoragePermissionRequestCallback storagePermissionRequestCallback;

    public RNCameraKitPackage() {

    }

    public RNCameraKitPackage(CameraPermissionRequestCallback cameraPermissionRequestCallback, StoragePermissionRequestCallback storagePermissionRequestCallback) {
        this.cameraPermissionRequestCallback = cameraPermissionRequestCallback;
        this.storagePermissionRequestCallback = storagePermissionRequestCallback;
    }

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
        List<NativeModule> modules = new ArrayList<>();

        CameraModule cameraModule = new CameraModule(reactContext);
        if (cameraPermissionRequestCallback != null) {
            cameraPermissionRequestCallback.setCameraModule(cameraModule);
        }
        modules.add(cameraModule);

        NativeGalleryModule galleryModule = new NativeGalleryModule(reactContext);
        if (storagePermissionRequestCallback != null) {
            storagePermissionRequestCallback.setGalleryModule(galleryModule);
        }
        modules.add(galleryModule);

        modules.add(new TorchModule(reactContext));

        return modules;
    }

    // Deprecated RN 0.47
    public List<Class<? extends JavaScriptModule>> createJSModules() {
        return Collections.emptyList();
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        List<ViewManager> viewManagers = new ArrayList<>();
        viewManagers.add(new GalleryViewManager());
        viewManagers.add(new CameraViewManager());
        return viewManagers;
    }

}