import {
  NativeModules,
  CameraRoll
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;
import _ from 'lodash';

async function getAlbumsWithThumbnails() {
  const albums = await CKGallery.getAlbumsWithThumbnails();
  return albums;
}

async function getThumbnailForAlbumName(albumName) {
  const albumsThumbnail = await CKGallery.getThumbnailForAlbumName(albumName);

  return albumsThumbnail;
}

function getPhotosForAlbum(albumName, numberOfPhotos, callback, error) {

  let groupType = (albumName === 'Camera Roll') ? 'SavedPhotos' : 'All';
  //const photoStream = ['Bursts', 'Recently Added', 'Selfies', 'Recently Added', 'Screenshots', 'My Photo Stream'];
  //if (_.include(photoStream, albumName)) {
  //  groupType = 'PhotoStream';
  //}



  const fetchParams = {
    first: numberOfPhotos,
    groupName: albumName,
    groupTypes: groupType,
  };
  CameraRoll.getPhotos(fetchParams)
            .then((data) =>  callback(data), (e) => error(e));
}

export default {
  getAlbumsWithThumbnails,
  getThumbnailForAlbumName,
  getPhotosForAlbum
}

