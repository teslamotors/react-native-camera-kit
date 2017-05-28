import {
  NativeModules,
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;

async function getAlbumsWithThumbnails() {
    const albums = await CKGallery.getAlbumsWithThumbnails();
    return albums;
}

async function getImageUriForId(imageId) {
  const images = await CKGallery.getImagesForIds([imageId]);
  if (!images) {
    return;
  }
  if (images.length === 1) {
    return images[0].uri;
  }
  return;
}

async function getImagesForIds(imagesId = [], imageQuality) {
  const images = await CKGallery.getImagesForIds(imagesId, imageQuality);
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
  return {selectedImageId, imageUri, width: nativeEvent.width, height: nativeEvent.height};
}


async function resizeImage(image = {}, quality = 'original') {
  if (quality === 'original') {
    return images;
  }
  const ans = await CKGallery.resizeImage(image, quality);
  return ans;
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
  requestDevicePhotosAuthorization,
  resizeImage
}
