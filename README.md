# react-native-camera-kit
Currently work in progress.

Native camera control.

## Install

#### Install using npm:
`npm install react-native-camera-kit --save`

####IOS
- Locate the module lib folder in your node modules: `PROJECT_DIR/node_modules/react-native-camera-kit/lib`
- Drag the `ReactNativeCameraKit.xcodeproj` project file into your project
- Add `libReactNativeCameraKit.a` to all your target **Linked Frameworks and Libraries** (prone to be forgotten) 

####Android
Add 

            include ':rncamerakit'
            project(':rncamerakit').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-camera-kit/android/')
to your project's `settings.gradle`

Then add 

            compile project(":rncamerakit")
to your app `app/build.gradle` in the `dependencies` section.

Then in `MainActivity.java` add:

            import com.wix.RNCameraKit.RNCameraKitPackage;
and in `getPackages` add 

            new RNCameraKitPackage() 
to the list


## Examples

###CameraKitCamera 
```javascript
<CameraKitCamera
            ref={(cam) => {
                  this.camera = cam;
                }} // should be only if u want to make some actions in this specific camera instance
            style={{flex: 1, justifyContent: 'flex-end'}}
            cameraOptions={{
                    flashMode: 'auto',
                    focusMode: 'on',
                    zoomMode: 'on'
                  }}
          />

```
####capture
Capture image

```javascript
const image = await this.camera.capture(true);
```

####setFlashMode

Set flesh mode (```auto```/```on```/```off```)

```javascript
const success = await this.camera.setFlashMode(newFlashData.mode);
```

####changeCamera

Change to fornt/rear camera

```javascript
const success = await this.camera.changeCamera();
```

###CameraKitGalleryView

```javascript
<CameraKitGalleryView
          ref={(gallery) => {
                            this.gallery = gallery;
                           }}
          style={{flex: 1, marginTop: 20}}
          minimumInteritemSpacing={10}
          minimumLineSpacing={10}
          albumName={<ALBUM_NAME>}
          columnCount={3}
          onSelected={(result) => {
              //result.nativeEvent.selected - ALL selected images Photos Framework ids
            }}
          selectedImage={require('<IMAGE_FILE_PATH>')}
          unSelectedImage={require('<IMAGE_FILE_PATH>')}
        />
```
