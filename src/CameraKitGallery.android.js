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
  return true;
}

async function requestDevicePhotosAuthorization() {
  return true;
}

export default {
  checkDevicePhotosAuthorizationStatus,
  requestDevicePhotosAuthorization,
  getAlbumsWithThumbnails,
  getImagesForIds
}
