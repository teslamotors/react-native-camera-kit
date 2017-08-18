
# react-native-camera-kit

Native camera control.

![](img/crazyUnicorn.png)  ![](img/zoom.png)

## Installation


#### Install using npm or yarn:

```bash
npm install react-native-camera-kit --save
```

Or if you're using yarn:

```bash
yarn add react-native-camera-kit
```

#### iOS

- Locate the module lib folder in your node modules: `PROJECT_DIR/node_modules/react-native-camera-kit/ios/lib`
- Drag the `ReactNativeCameraKit.xcodeproj` project file into your project
- Add `libReactNativeCameraKit.a` to all your target **Linked Frameworks and Libraries** (prone to be forgotten)

#### Android

Add the following to your project's `settings.gradle` file:


```diff
+ include ':rncamerakit'
+ project(':rncamerakit').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-camera-kit/android/')
```

Then add to your app `app/build.gradle` in the `dependencies` section:

```diff
+ compile project(":rncamerakit")
```

Then in `MainApplication.java` add:

```diff
+ import com.wix.RNCameraKit.RNCameraKitPackage;
```

And in the package list in the same file (e.g. `getPackages`) add:

```diff
+ new RNCameraKitPackage()
```

## APIs

### CameraKitCamera - Camera component 

```js
<CameraKitCamera
  ref={cam => this.camera = cam}
  style={{
    flex: 1,
    backgroundColor: 'white'
  }}
  cameraOptions={{
    flashMode: 'auto',             // on/off/auto(default)
    focusMode: 'on',               // off/on(default)
    zoomMode: 'on',                // off/on(default)
    ratioOverlay:'1:1',            // optional, ratio overlay on the camera and crop the image seamlessly
    ratioOverlayColor: '#00000077' // optional
  }}
/>
```

### CameraKitCamera cameraOptions

Attribute         | Values                 | Description
----------------- | ---------------------- | -----------
`flashMode`         |`'on'`/`'off'`/`'auto'` | camera flash mode (default is `auto`)
`focusMode`         | `'on'`/`'off'`         | camera focus mode (default is `on`)
`zoomMode`          | `'on'`/`'off'`         | camera zoom mode
`ratioOverlay`      | `['int':'int', ...]`   | overlay on top of the camera view (crop the image to the selected size) Example: `['16:9', '1:1', '3:4']`
`ratioOverlayColor` |  Color                 | any color with alpha (default is ```'#ffffff77'```)


### CameraKitCamera API

#### checkDeviceCameraAuthorizationStatus

```js
const isCameraAuthorized = await CameraKitCamera.checkDeviceCameraAuthorizationStatus();
```

return values:

`AVAuthorizationStatusAuthorized` returns `true`

`AVAuthorizationStatusNotDetermined` returns `-1`

otherwise, returns ```false```

#### requestDeviceCameraAuthorization

```js
const isUserAuthorizedCamera = await CameraKitCamera.requestDeviceCameraAuthorization();
```

`AVAuthorizationStatusAuthorized` returns `true`

otherwise, returns `false`

#### capture - must have the wanted camera capture reference

Capture image (`shouldSaveToCameraRoll: boolean`)

```js
const image = await this.camera.capture(true);
```

#### setFlashMode - must have the wanted camera capture reference

Set flash mode (`auto`/`on`/`off`)

```js
const success = await this.camera.setFlashMode(newFlashData.mode);
```

#### changeCamera - must have the wanted camera capture reference

Change to fornt/rear camera

```js
const success = await this.camera.changeCamera();
```

### CameraKitGalleryView - Gallery grid component

Native Gallery View (based on `UICollectionView`(iOS) and ` RecyclerView` (Android))

![](img/camerakitgalleryview.png)

```js
<CameraKitGalleryView
  ref={gallery => this.gallery = gallery}
  style={{flex: 1, marginTop: 20}}
  minimumInteritemSpacing={10}
  minimumLineSpacing={10}
  albumName={<ALBUM_NAME>}
  columnCount={3}
  onTapImage={event => {
    // event.nativeEvent.selected - ALL selected images ids
  }}
  selectedImages={<MAINTAIN_SELECETED_IMAGES>}
  selectedImageIcon={require('<IMAGE_FILE_PATH>'))}
  unSelectedImageIcon={require('<IMAGE_FILE_PATH>')}
/>
```

Attribute | Values | Description
-------- | ----- | ------------
`minimumInteritemSpacing`        | Float             | Minimum inner Item spacing
`minimumLineSpacing`             | Float             | Minimum line spacing
`imageStrokeColor`               | Color             | Image stroke color
`albumName`                      | String            | Album name to show
`columnCount`                    | Integer           | How many clumns in one row
`onTapImage`                     | Function          | Callback when image tapped
`selectedImages`                 | Array             | Selected images (will show the selected badge)
`selectedImageIcon`              | `require(_PATH_)` | - _DEPRECATED_ use Selection - Selected image badge image
`unSelectedImageIcon`            | `require(_PATH_)` | - _DEPRECATED_ use Selection - Unselected image badge image
`selection`                      | Object            | See [Selection section](#selection)
`getUrlOnTapImage`               | Boolean           | iOS only - On image tap return the image internal  (tmp folder) uri (intead of `Photos.framework` asset id)
`customButtonStyle`              | Object            | See [Custom Button](#custom-button) section
`onCustomButtonPress`            | Function          | Callback when custom button tapped
`contentInset` (iOS)             | Object            | The amount by which the gellery view content is inset from its edges (similar to `ScrollView` contentInset)
`remoteDownloadIndicatorType`    | String (`'spinner'` / `'progress-bar'` / `'progress-pie'`) | iOS only - see [Images stored in iCloud](#images-stored-in-iCloud)
`remoteDownloadIndicatorColor`   | Color             | iOS only - Color of the remote download indicator to show  
`onRemoteDownloadChanged`        | Function          | iOS only - Callback when the device curentlly download remote image stored in the iCloud.

#### Custom Button

Attribute | Values | Description
-------- | ----- | ------------
`image` | `require(_PATH_)` | Custom button image
`backgroundColor` | Color | Custom button background color

#### Selection

Attribute | Values | Description
-------- | ----- | ------------
`selectedImage` |`require(_PATH_)`|Selected image badge image
`unselectedImage` |`require(_PATH_)`|Unselected image badge image
`imagePosition` |`bottom/top-right/left` / `center`|  Selected/Unselected badge image position (Default:`top-right`)
`overlayColor` |Color| Image selected overlay color
`imageSizeAndroid` |`large`/`medium`| Android Only - Selected badge image size

#### Images stored in iCloud 
On iOS images can be stored in iCould if the device is **low on space** which means full-resolution photos automatically replaced with optimized version and full resolution versions are stored in iCloud.
In this case, we need to download the image from iCloud and *Photos Framework* by Apple does a great job, so as we can guess, download takes some time and we deal with UI, so we need to show some loading/progress indicator. 
In oreder to do so, we provide 3 types of loading/progress inidcators:

Sets `remoteDownloadIndicatorType` prop (and `remoteDownloadIndicatorColor` in order to sets the Color) on CameraKitGalleryView:

Attribute | Values
-------- | :-----:
 `'spinner'`     | ![](img/spinner.png)
 `'progress-bar'`| ![](img/progressBar.png)
 `'progress-pie'`| ![](img/pie.png)
 
 >In order to simpulate this loading behaviour, since reach low on storage situation is hard, simply add this prop `iCloudDownloadSimulateTime={TIME_IN_SECONDS}`, just **DO NOT FORGET TO REMOVE IT**.

## QR Code 

Want/Need QR Code support embed in this package, please vote [HERE](https://github.com/wix/react-native-camera-kit/issues/60) 


## Credits

* [M13ProgressSuite](https://github.com/Marxon13/M13ProgressSuite) component by Marxon13 - A suite containing many tools to display progress information on iOS.

## License

The MIT License.

See [LICENSE](LICENSE)
