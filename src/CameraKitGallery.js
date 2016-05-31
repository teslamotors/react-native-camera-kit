import {
	NativeModules
} from 'react-native';

var CKGallery = NativeModules.CKGalleryManager;


async function getAlbums() {
	const albumsName = await CKGallery.getAllAlbumsName();
	return albumsName;
}

export default {
	getAlbums
}

