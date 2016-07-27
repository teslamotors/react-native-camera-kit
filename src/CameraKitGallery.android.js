import {NativeModules} from 'react-native';
const NativeGalleryModule = NativeModules.NativeGalleryModule;
import _ from 'lodash';

async function getAlbumsWithThumbnails() {
  const albums = await NativeGalleryModule.getAlbumsWithThumbnails();
  return albums;
}

async function getImagesForIds(imagesUris = []) {
  const images = await NativeGalleryModule.getImagesForUris(imagesUris);
  return images;
}

async function checkDeviceGalleryAuthorizationStatus() {
  //const deviceAutorizationStatus = await NativeCameraAction.checkDeviceAuthorizationStatus();
  //
  //return deviceAutorizationStatus;
  return true;
}

export default {
  checkDeviceGalleryAuthorizationStatus,
  getAlbumsWithThumbnails,
  getImagesForIds
}
