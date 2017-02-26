package com.wix.RNCameraKit.gallery.permission;

import com.wix.RNCameraKit.gallery.NativeGalleryModule;

public class StoragePermissionRequestCallback {
    private NativeGalleryModule galleryModule;

    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        galleryModule.onRequestPermissionsResult(requestCode, permissions, grantResults);
    }

    public void setGalleryModule(NativeGalleryModule galleryModule) {
        this.galleryModule = galleryModule;
    }
}
