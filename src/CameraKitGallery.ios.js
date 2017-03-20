import {
  NativeModules,
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;

async function getAlbumsWithThumbnails() {
    const albums = await CKGallery.getAlbumsWithThumbnails();
    return albums;
}

async function getImageUriForId(imageId) {
  const images = await CKGallery.getImagesForIds(imagesId);
  if (!images) {
    return;
  }
  return images.uri;
}

async function getImagesForIds(imagesId = []) {
  const images = await CKGallery.getImagesForIds(imagesId);
  return images;
}

async function getImageForTapEvent(nativeEvent) {
  let selectedImageId;
  let imageUri;
  if (nativeEvent.selectedId) {
    selectedImageId = nativeEvent.selectedId;
    imageUri = nativeEvent.selected;
  } else {
    selectedImageId = nativeEvent.selected;
    imageUri = await getImageUriForId(selectedImageId);
  }
  return {selectedImageId, imageUri};
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
  getImageUriForId,
  getImagesForIds,
  getImageForTapEvent,
  checkDevicePhotosAuthorizationStatus,
  requestDevicePhotosAuthorization
}
