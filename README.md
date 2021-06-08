<h1 align="center">
    🎈 React Native Camera Kit
</h1>

<p align="center">
  A <strong>high performance, easy to use, rock solid</strong><br>
  camera library for React Native apps.
</p>

<p align="center">
  <a href="https://github.com/teslamotors/react-native-camera-kit/blob/master/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="React Native Camera Kit is released under the MIT license." />
  </a>
  <a href="https://www.npmjs.org/package/react-native-camera-kit">
    <img src="https://badge.fury.io/js/react-native-camera-kit.svg" alt="Current npm package version." />
  </a>
</p>
<table>
  <tr>
    <td>
      <img src="images/screenshot.jpg"/>
    </td>
    <td>
      <ul>
        <li><h3>Cross Platform (iOS and Android)</h3></li>
        <li><h3>Optimized for performance and high photo capture rate</h3></li>
        <li><h3>QR / Barcode scanning support</h3></li>
        <li><h3>Camera preview support in iOS simulator</h3></li>
      </ul>
    </td>
  </tr>
</table>

## Installation (RN > 0.60)

```bash
yarn add react-native-camera-kit
```

```bash
cd ios && pod install && cd ..
```

Android:
[Add Kotlin to your project](./docs/kotlin.md)

## Permissions

#### Android

Add the following uses-permission to your `AndroidManifest.xml` (usually found at: `android/src/main/`)

```java
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

#### iOS

Add the following usage descriptions to your `Info.plist` (usually found at: `ios/PROJECT_NAME/`)

```xml
<key>NSCameraUsageDescription</key>
<string>For taking photos</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>For saving photos</string>
```

## Running the example project

- `yarn bootstrap`
- `yarn example ios` or `yarn example android`

## Components

### CameraScreen

Full screen camera component that holds camera state and provides camera controls

```ts
import { CameraScreen } from 'react-native-camera-kit';
```

```tsx
<CameraScreen
  actions={{ rightButtonText: 'Done', leftButtonText: 'Cancel' }}
  onBottomButtonPressed={(event) => this.onBottomButtonPressed(event)}
  flashImages={{
    // optional, images for flash state
    on: require('path/to/image'),
    off: require('path/to/image'),
    auto: require('path/to/image'),
  }}
  cameraFlipImage={require('path/to/image')} // optional, image for flipping camera button
  captureButtonImage={require('path/to/image')} // optional, image capture button
  torchOnImage={require('path/to/image')} // optional, image for toggling on flash light
  torchOffImage={require('path/to/image')} // optional, image for toggling off flash light
  hideControls={false} // (default false) optional, hides camera controls
  showCapturedImageCount={false} // (default false) optional, show count for photos taken during that capture session
/>
```

#### Barcode / QR Code Scanning

Additionally, the camera screen can be used for barcode scanning

```tsx
<CameraScreen
  ...
  // Barcode props
  scanBarcode={true}
  onReadCode={(event) => Alert.alert('QR code found')} // optional
  showFrame={true} // (default false) optional, show frame with transparent layer (qr code or barcode will be read on this area ONLY), start animation for scanner,that stoped when find any code. Frame always at center of the screen
  laserColor='red' // (default red) optional, color of laser in scanner frame
  frameColor='white' // (default white) optional, color of border of scanner frame
/>
```

### Camera

Barebones camera component

```ts
import { Camera, CameraType } from 'react-native-camera-kit';
```

```tsx
<Camera
  ref={(ref) => (this.camera = ref)}
  cameraType={CameraType.Back} // front/back(default)
/>
```

### Camera Props (Optional)

| Props                          | Type                    | Description                                                                                                                                                                                                                                                                                                                                   |
| ------------------------------ | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flashMode`                    | `'on'`/`'off'`/`'auto'` | Camera flash mode. Default: `auto`                                                                                                                                                                                                                                                                                                            |
| `focusMode`                    | `'on'`/`'off'`          | Camera focus mode. Default: `on`                                                                                                                                                                                                                                                                                                              |
| `zoomMode`                     | `'on'`/`'off'`          | Enable pinch to zoom camera. Default: `on`                                                                                                                                                                                                                                                                                                    |
| `torchMode`                    | `'on'`/`'off'`          | Toggle flash light when camera is active. Default: `off`                                                                                                                                                                                                                                                                                      |
| `ratioOverlay`                 | `['int':'int', ...]`    | Show a guiding overlay in the camera preview for the selected ratio. Does not crop image as of v9.0. Example: `['16:9', '1:1', '3:4']`                                                                                                                                                                                                        |
| `ratioOverlayColor`            | Color                   | Any color with alpha. Default: `'#ffffff77'`                                                                                                                                                                                                                                                                                                  |
| `resetFocusTimeout`            | Number                  | **iOS only.** Dismiss tap to focus after this many milliseconds. Default `0` (disabled). Example: `5000` is 5 seconds.                                                                                                                                                                                                                            |
| `resetFocusWhenMotionDetected` | Boolean                 | **iOS only.** Dismiss tap to focus when focus area content changes. Native iOS feature, see documentation: https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624644-subjectareachangemonitoringenabl?language=objc). Default `true`.                                                                                        |
| `saveToCameraRoll`             | Boolean                 | Using the camera roll is slower than using regular files stored in your app. On an iPhone X in debug mode, on a real phone, we measured around 100-150ms processing time to save to the camera roll. _<span style="color: red">**Note:**</span> This only work on real devices. It will hang indefinitly on simulators._ Default `true`                         |
| `saveToCameraRollWithPhUrl`    | Boolean                 | **iOS only.** If true, speeds up photo taking by about 5-50ms (measured on iPhone X) by only returning a [rn-cameraroll-compatible](https://github.com/react-native-community/react-native-cameraroll/blob/a09af08f0a46a98b29f6ad470e59d3dc627864a2/ios/RNCAssetsLibraryRequestHandler.m#L36) `ph://..` URL instead of a regular `file://..` URL. |  |
| `onOrientationChange`          | Function                | Callback when physical device orientation changes. Returned event contains `orientation`. Ex: `onOrientationChange={(event) => console.log(event.nativeEvent.orientation)}`. Use `import { Orientation } from 'react-native-camera-kit'; if (event.nativeEvent.orientation === Orientation.PORTRAIT) { ... }` to understand the new value |

### Barcode Props (Optional)

| Props          | Type     | Description                                                                                                                                                                                |
| -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `scanBarcode`  | Boolean  | Enable barcode scanner. Default: `false`                                                                                                                                                   |
| `showFrame`    | Boolean  | Show frame in barcode scanner. Default: `false`                                                                                                                                            |
| `laserColor`   | Color    | Color of barcode scanner laser visualization. Default: `red`                                                                                                                               |
| `frameColor`   | Color    | Color of barcode scanner frame visualization. Default: `yellow`                                                                                                                            |
| `surfaceColor` | Color    | Color of barcode scanner surface visualization. Default: `blue`                                                                                                                            |
| `onReadCode`   | Function | Callback when scanner successfully reads barcode. Returned event contains `codeStringValue`. Default: `null`. Ex: `onReadCode={(event) => console.log(event.nativeEvent.codeStringValue)}` |

### Imperative API

_Note: Must be called on a valid camera ref_

#### capture()

Capture image as JPEG.

If you are not using `saveToCameraRoll` then a temporary file is created. You *must* move this file to a permanent location (e.g. the app's 'Documents' folder) if you need it beyond the current session of the app as it may be deleted when the user leaves the app. You can move files by using a file system library such as [react-native-fs](https://github.com/itinance/react-native-fs) or [expo-filesystem](https://docs.expo.io/versions/latest/sdk/filesystem/).
(On Android we currently have an unsupported `outputPath` prop but it's subject to change at any time).

Note that the reason you're getting a URL despite it being a file is because Android 10+ encourages URIs. To keep things consistent regardless of settings or platform we always send back a URI.

```ts
const { uri } = await this.camera.capture();
// uri = 'file:///data/user/0/com.myorg.myapp/cache/ckcap123123123123.jpg'
```

If you want to store it permanently, here's an example using [react-native-fs](https://github.com/itinance/react-native-fs):
```ts
import RNFS from 'react-native-fs';
// [...]
let { uri } = await this.camera.capture();
if (uri.startsWith('file://')) {
  // Platform dependent, iOS & Android uses '/'
  const pathSplitter = '/';
  // file:///foo/bar.jpg => /foo/bar.jpg
  const filePath = uri.replace('file://', '');
  // /foo/bar.jpg => [foo, bar.jpg]
  const pathSegments = filePath.split(pathSplitter);
  // [foo, bar.jpg] => bar.jpg
  const fileName = pathSegments[pathSegments.length - 1];

  await RNFS.moveFile(filePath, `${RNFS.DocumentDirectoryPath}/${fileName}`);
  uri = `file://${destFilePath}`;
}
```

#### checkDeviceCameraAuthorizationStatus (**iOS only**)

```ts
const isCameraAuthorized = await Camera.checkDeviceCameraAuthorizationStatus();
```

return values:

`AVAuthorizationStatusAuthorized` returns `true`

`AVAuthorizationStatusNotDetermined` returns `-1`

otherwise, returns `false`

#### requestDeviceCameraAuthorization (**iOS only**)

```ts
const isUserAuthorizedCamera = await Camera.requestDeviceCameraAuthorization();
```

`AVAuthorizationStatusAuthorized` returns `true`

otherwise, returns `false`

## Contributing

- Pull Requests are welcome, if you open a pull request we will do our best to get to it in a timely manner
- Pull Request Reviews are even more welcome! we need help testing, reviewing, and updating open PRs
- If you are interested in contributing more actively, please contact us.

## License

The MIT License.

See [LICENSE](LICENSE)
