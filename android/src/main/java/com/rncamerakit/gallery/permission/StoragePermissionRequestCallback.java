package com.rncamerakit.gallery.permission;

import com.rncamerakit.gallery.NativeGalleryModule;

public class StoragePermissionRequestCallback {
    private NativeGalleryModule galleryModule;

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        galleryModule.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    public void setGalleryModule(NativeGalleryModule galleryModule) {
        this.galleryModule = galleryModule;
    }
}
