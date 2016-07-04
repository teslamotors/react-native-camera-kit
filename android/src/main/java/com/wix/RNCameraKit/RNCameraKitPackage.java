package com.wix.RNCameraKit;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.wix.RNCameraKit.camera.CameraModule;
import com.wix.RNCameraKit.camera.CameraViewManager;
import com.wix.RNCameraKit.gallery.GalleryViewManager;
import com.wix.RNCameraKit.gallery.NativeGalleryModule;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class RNCameraKitPackage implements ReactPackage {

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
      List<NativeModule> modules = new ArrayList<>();
      modules.add(new NativeGalleryModule(reactContext));
      modules.add(new CameraModule(reactContext));
      return modules;
  }

  @Override
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