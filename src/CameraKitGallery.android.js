import {NativeModules} from 'react-native';
const NativeGalleryModule = NativeModules.NativeGalleryModule;
import _ from 'lodash';

async function getAlbumsWithThumbnails() {
  const albums = await NativeGalleryModule.getAlbumsWithThumbnails();
  return albums;
}


async function getPhotosForAlbum(albumName, numberOfPhotos) {

}

export default {
  getAlbumsWithThumbnails,
  getPhotosForAlbum
}
