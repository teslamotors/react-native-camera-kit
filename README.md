# react-native-camera-kit

Native camera control.

![](img/crazyUnicorn.png)  ![](img/zoom.png)

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


## How to use

###CameraKitCamera inside the `render` function
```javascript
<CameraKitCamera
        ref={(cam) => {
        					this.camera = cam;
        					}
        		}
        style={{flex: 1, backgroundColor:'white'}}
        cameraOptions={{
                    flashMode: 'auto',             // on/off/auto(default)
                    focusMode: 'on',               // off/on(default)
                    zoomMode: 'on',                // off/on(default)
                    ratioOverlay:'1:1',            // optional, ratio overlay on the camera and crop the image seamlessly 
                    ratioOverlayColor: '#00000077' // optional
                    }}
/>
```
###CameraKitCamera cameraOptions

Attribute  | Values | Description
-------- | ----- | ------ | ------------
flashMode |`'on'`/`'off'`/`'auto'` | camera flash mode (default is `auto`)
focusMode | `'on'`/`'off'` | camera focus mode (default is `on`)
zoomMode | `'on'`/`'off'`/ | camera zoom mode 
ratioOverlay | `['int':'int', ...]` | overlay ontop of the camera view (crop the image to the selected size) Example: `['16:9', '1:1', '3:4']`
ratioOverlayColor |  Color | any color with alpha (default is ```'#ffffff77'```)


###CameraKitCamera API

####checkDeviceCameraAuthorizationStatus
```javascript
const isCameraAuthorized = await CameraKitCamera.checkDeviceCameraAuthorizationStatus();
```
return values:

`AVAuthorizationStatusAuthorized` returns `true`

`AVAuthorizationStatusNotDetermined` returns `-1`

otherwise, returns ```false```

####requestDeviceCameraAuthorization
```javascript
const isUserAuthorizedCamera = await CameraKitCamera.requestDeviceCameraAuthorization();
```
`AVAuthorizationStatusAuthorized` returns `true`

otherwise, returns `false`


####capture
Capture image

```javascript
const image = await this.camera.capture(true);
```

####setFlashMode

Set flash mode (`auto`/`on`/`off`)

```javascript
const success = await this.camera.setFlashMode(newFlashData.mode);
```

####changeCamera

Change to fornt/rear camera

```javascript
const success = await this.camera.changeCamera();
```

###CameraKitGalleryView

Native Gallery View (based on `UICollectionView`)

![](img/camerakitgalleryview.png)


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
          onTapImage={(event) => {
              //result.nativeEvent.selected - ALL selected images Photos Framework ids
          }}
          selectedImages={<MAINTAIN_SELECETED_IMAGES>}
          selectedImageIcon={require('<IMAGE_FILE_PATH>'))}
          unSelectedImageIcon={require('<IMAGE_FILE_PATH>')}
/>
```

Attribute | Values | Description
-------- | ----- | ------------
minimumInteritemSpacing | float  | Minimum inner Item spacing
minimumLineSpacing | Float | Minimum line spacing
imageStrokeColor | Color | Image storke color
albumName | String |Album name to show
columnCount | Integer | How many clumns in one row
onTapImage | Function | Callback when image tapped
selectedImages | Array | Selected images (will show the selected badge)
selectedImageIcon | `require(_PATH_)`  | - _DEPRECATED_ use Selection - Selected image badge image
unSelectedImageIcon | `require(_PATH_)` | - _DEPRECATED_ use Selection - Unselected image badge image
selection | Object |   See Selection section 
getUrlOnTapImage | Boolean| iOS only - On image tap return the image internal  (tmp folder) uri (intead of `Photos.framework` asset id)
customButtonStyle | Object | See Custom Button section
onCustomButtonPress | Function | Callback when custom button tapped
contentInset (iOS) | Object | The amount by which the gellery view content is inset from its edges (similar to `ScrollView` contentInset)

#### Custom Button
Attribute | Values | Description
-------- | ----- | ------------
image | `require(_PATH_)` | Custom button image
backgroundColor | Color | Custom button background color

#### Selection


Attribute | Values | Description
-------- | ----- | ------------
selectedImage |`require(_PATH_)`|Selected image badge image
unselectedImage |`require(_PATH_)`|Unselected image badge image
imagePosition |`bottom/top-right/left` / `center`|  Selected/Unselected badge image position (Default:`top-right`)
overlayColor |Color| Image selected overlay color
imageSizeAndroid |`large`/`medium`| Android Only - Selected badge image size