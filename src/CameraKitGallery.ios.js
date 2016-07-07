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


export default {
  getAlbumsWithThumbnails,
  getImagesForIds
}
