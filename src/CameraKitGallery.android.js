import {NativeModules} from 'react-native';
const NativeGalleryManager = NativeModules.NativeGalleryManager;
import _ from 'lodash';

async function getAlbumsWithThumbnails() {
  const albums = await NativeGalleryManager.getAlbumsWithThumbnails();
  return albums;
}


async function getPhotosForAlbum(albumName, numberOfPhotos) {

}

export default {
  getAlbumsWithThumbnails,
  getPhotosForAlbum
}
