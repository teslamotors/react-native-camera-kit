import _ from 'lodash';
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


//function getPhotosForAlbum(albumName, numberOfPhotos, callback, error) {
//
//  let groupType = (albumName.toLowerCase() === 'all photos') ? 'SavedPhotos' : 'All';
//
//  const fetchParams = {
//    first: numberOfPhotos,
//    groupTypes: groupType,
//    assetType: 'Photos'
//  };
//
//  if (albumName.toLowerCase() !== 'all photos') {
//    fetchParams.groupName = albumName;
//  }
//
//
//  CameraRoll.getPhotos(fetchParams)
//            .then((data) => callback(data), (e) => error(e));
//}

export default {
  getAlbumsWithThumbnails,
  getImagesForIds
}
