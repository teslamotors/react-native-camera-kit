import {
	NativeModules
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;


async function getAlbums() {
	const albumsName = await CKGallery.getAllAlbumsName();
	return albumsName;
}

async function getThumbnailForAlbumName(albumName) {
	const albumsThumbnail = await CKGallery.getThumbnailForAlbumName(albumName);
	return albumsThumbnail;
}

export default {
	getAlbums,
	getThumbnailForAlbumName
}

