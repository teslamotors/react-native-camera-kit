import {NativeModules} from 'react-native';
const NativeGalleryModule = NativeModules.NativeGalleryModule;

async function getAlbumsWithThumbnails() {
  return await NativeGalleryModule.getAlbumsWithThumbnails();
}

async function getImageUriForId(imageId) {
  // Return what getImagesForIds() typically returns in the 'uri' field.
  return `file://${imageId}`;
}

async function getImagesForIds(imagesUris = []) {
  return await NativeGalleryModule.getImagesForUris(imagesUris);
}

async function getImageForTapEvent(nativeEvent) {
  const selectedImageId = nativeEvent.selected;
  const imageUri = selectedImageId && await getImageUriForId(selectedImageId);
  return {selectedImageId, imageUri, width: nativeEvent.width, height: nativeEvent.height};
}

async function getImagesForCameraEvent(event) {
  if (!event.captureImages) {
    return [];
  }

  const images = [];
  event.captureImages.forEach(async (image) => {
    images.push({
      ...image,
      uri: await getImageUriForId(image.uri)
    });
  });
  return images;
}

async function checkDevicePhotosAuthorizationStatus() {
  return await NativeGalleryModule.checkDeviceStorageAuthorizationStatus();
}

async function requestDevicePhotosAuthorization() {
  return await NativeGalleryModule.requestDeviceStorageAuthorization();
}

async function resizeImage(image = {}, quality = 'original') {
    if (quality === 'original') {
        return images;
    }
  return await NativeGalleryModule.resizeImage(image, quality);
}


export default {
  checkDevicePhotosAuthorizationStatus,
  requestDevicePhotosAuthorization,
  getAlbumsWithThumbnails,
  getImageUriForId,
  getImagesForIds,
  getImageForTapEvent,
  getImagesForCameraEvent,
  resizeImage
}
