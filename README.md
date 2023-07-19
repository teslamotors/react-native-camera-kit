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

### Camera

Barebones camera component if you need advanced/customized interface

```ts
import { Camera, CameraType } from 'react-native-camera-kit';
```

```tsx
<Camera
  ref={(ref) => (this.camera = ref)}
  cameraType={CameraType.Back} // front/back(default)
  flashMode='auto'
/>
```

#### Barcode / QR Code Scanning

Additionally, the Camera can be used for barcode scanning

```tsx
<Camera
  ...
  // Barcode props
  scanBarcode={true}
  onReadCode={(event) => Alert.alert('QR code found')} // optional
  showFrame={true} // (default false) optional, show frame with transparent layer (qr code or barcode will be read on this area ONLY), start animation for scanner,that stoped when find any code. Frame always at center of the screen
  laserColor='red' // (default red) optional, color of laser in scanner frame
  frameColor='white' // (default white) optional, color of border of scanner frame
/>
```

### Camera Props (Optional)

| Props                          | Type                             | Description                                                                                                                                                                                                                                                                                                                               |
| ------------------------------ | -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ref`                          | Ref                              | Reference on the camera view                                                                                                                                                                                                                                                                                                              |
| `style`                        | StyleProp\<ViewStyle>            | Style to apply on the camera view                                                                                                                                                                                                                                                                                                         |
| `flashMode`                    | `'on'`/`'off'`/`'auto'`          | Camera flash mode. Default: `auto`                                                                                                                                                                                                                                                                                                        |
| `focusMode`                    | `'on'`/`'off'`                   | Camera focus mode. Default: `on`                                                                                                                                                                                                                                                                                                          |
| `zoomMode`                     | `'on'`/`'off'`                   | Enable the pinch to zoom gesture. Default: `on`                                                                                                                                                                                                                                                                                                |
| `zoom`                         | `number`                   | Control the zoom. Default: `1.0`                                                                                                                                                                                                                                                                                                |
| `maxZoom`                         | `number`                   | Maximum zoom allowed (but not beyond what camera allows). Default: `undefined` (camera default max)                                                                                                                                                                                                                                                                                                |
| `onZoom`          | Function                         | Callback when user makes a pinch gesture, regardless of what the `zoom` prop was set to. Returned event contains `zoom`. Ex: `onZoom={(e) => console.log(e.nativeEvent.zoom)}`. |
| `torchMode`                    | `'on'`/`'off'`                   | Toggle flash light when camera is active. Default: `off`                                                                                                                                                                                                                                                                                  |
| `cameraType`                   | CameraType.Back/CameraType.Front | Choose what camera to use. Default: `CameraType.Back`                                                                                                                                                                                                                                                                                     |
| `onOrientationChange`          | Function                         | Callback when physical device orientation changes. Returned event contains `orientation`. Ex: `onOrientationChange={(event) => console.log(event.nativeEvent.orientation)}`. Use `import { Orientation } from 'react-native-camera-kit'; if (event.nativeEvent.orientation === Orientation.PORTRAIT) { ... }` to understand the new value |
| **iOS only**                   |
| `ratioOverlay`                 | `'int:int'`                      | Show a guiding overlay in the camera preview for the selected ratio. Does not crop image as of v9.0. Example: `'16:9'`                                                                                                                                                                                                                    |
| `ratioOverlayColor`            | Color                            | Any color with alpha. Default: `'#ffffff77'`                                                                                                                                                                                                                                                                                              |
| `resetFocusTimeout`            | `number`                           | Dismiss tap to focus after this many milliseconds. Default `0` (disabled). Example: `5000` is 5 seconds.                                                                                                                                                                                                                                  |
| `resetFocusWhenMotionDetected` | Boolean                          | Dismiss tap to focus when focus area content changes. Native iOS feature, see documentation: https://developer.apple.com/documentation/avfoundation/avcapturedevice/1624644-subjectareachangemonitoringenabl?language=objc). Default `true`.                                                                                              |
| `scanThrottleDelay`            | `number`                           | Duration between scan detection in milliseconds. Default 2000 (2s)                                                                                                                                                                                                                                                                        |
| **Barcode only**               |
| `scanBarcode`                  | `boolean`                          | Enable barcode scanner. Default: `false`                                                                                                                                                                                                                                                                                                  |
| `showFrame`                    | `boolean`                          | Show frame in barcode scanner. Default: `false`                                                                                                                                                                                                                                                                                           |
| `laserColor`                   | Color                            | Color of barcode scanner laser visualization. Default: `red`                                                                                                                                                                                                                                                                              |
| `frameColor`                   | Color                            | Color of barcode scanner frame visualization. Default: `yellow`                                                                                                                                                                                                                                                                           |
| `onReadCode`                   | Function                         | Callback when scanner successfully reads barcode. Returned event contains `codeStringValue`. Default: `null`. Ex: `onReadCode={(event) => console.log(event.nativeEvent.codeStringValue)}`                                                                                                                                                |

### Imperative API

_Note: Must be called on a valid camera ref_

#### capture()

Capture image as JPEG.

A temporary file is created. You _must_ move this file to a permanent location (e.g. the app's 'Documents' folder) if you need it beyond the current session of the app as it may be deleted when the user leaves the app. You can move files by using a file system library such as [react-native-fs](https://github.com/itinance/react-native-fs) or [expo-filesystem](https://docs.expo.io/versions/latest/sdk/filesystem/).
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
