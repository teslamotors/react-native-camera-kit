import {
  NativeModules,
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;

async function getAlbumsWithThumbnails() {
    const albums = await CKGallery.getAlbumsWithThumbnails();
    return albums;
}

async function getImagesForIds(imagesId = []) {
  const images = await CKGallery.getImagesForIds(imagesId);
  return images;
}

async function checkDevicePhotosAuthorizationStatus() {
    const isAuthorized = await CKGallery.checkDevicePhotosAuthorizationStatus();
    return isAuthorized;
}

async function requestDevicePhotosAuthorization() {
  const isAuthorized = await CKGallery.requestDevicePhotosAuthorization();
  return isAuthorized;
}

export default {
  getAlbumsWithThumbnails,
  getImagesForIds,
  checkDevicePhotosAuthorizationStatus,
  requestDevicePhotosAuthorization
}
