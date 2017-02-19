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

async function checkDevicePhotosAuthorizationStatus() {
  const isAuthorized = await NativeGalleryModule.checkDeviceStorageAuthorizationStatus();
  return isAuthorized;
}

async function requestDevicePhotosAuthorization() {
  const isAuthorized = await NativeGalleryModule.requestDeviceStorageAuthorization();
  return isAuthorized;
}

export default {
  checkDevicePhotosAuthorizationStatus,
  requestDevicePhotosAuthorization,
  getAlbumsWithThumbnails,
  getImagesForIds
}
