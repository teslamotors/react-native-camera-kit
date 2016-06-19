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

  let groupType = (albumName.toLowerCase() === 'all photos') ? 'SavedPhotos' : 'All';

  const fetchParams = {
    first: numberOfPhotos,
    groupTypes: groupType
  };

  if (albumName.toLowerCase() !== 'all photos') {
    fetchParams.groupName = albumName;
  }

  CameraRoll.getPhotos(fetchParams)
            .then((data) => callback(data), (e) => error(e));
}

export default {
  getAlbumsWithThumbnails,
  getThumbnailForAlbumName,
  getPhotosForAlbum
}
