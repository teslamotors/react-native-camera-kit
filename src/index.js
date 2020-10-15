import { NativeModules } from "react-native";

import CameraKitGallery from "./CameraKitGallery";
import CameraKitCamera from "./CameraKitCamera";
import CameraKitGalleryView from "./CameraKitGalleryView";
import CameraKitCameraScreen from "./CameraScreen/CameraKitCameraScreen";

const { CameraKit } = NativeModules;

export default CameraKit;

export {
  CameraKitGallery,
  CameraKitCamera,
  CameraKitGalleryView,
  CameraKitCameraScreen,
};
