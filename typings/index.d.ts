declare module 'react-native-camera-kit' {

    import { StyleProp, ViewStyle, ImageRequireSource, ViewProps } from 'react-native';

    export type Color = string;

    export type GalleryImage = {
        id: string,
        selected: string
        height: number
        width: number
    }

    export type OnTapEvent = {
        nativeEvent: GalleryImage
    }
    export type CustomButtom = {
        image: ImageRequireSource
        backgroundColor: Color
    }

    export type Selection = {
        /**
         * Selected image badge image
         */
        selectedImage: ImageRequireSource
        /**
         * Unselected image badge image
         */
        unselectedImage: ImageRequireSource
        /**
         * Selected/Unselected badge image position 
         * (Default:top-right)
         */
        imagePosition: 'bottom' | 'top-right' | 'left' | 'center'
        /**
         * Image selected overlay color
         */
        overlayColor: Color
        /**
         * Android Only - Selected badge image size
         */
        imageSizeAndroid: 'large' | 'medium'
    }

    export interface CameraKitGalleryViewProps extends ViewProps {
        style?: StyleProp<ViewStyle>
        /**
         * Minimum inner Item spacing
         */
        minimumInteritemSpacing?: number
        /**
         * Minimum line spacing
         */
        minimumLineSpacing?: number
        /**
         * Image stroke color
         */
        imageStrokeColor?: Color
        /**
         * Image stroke color width
         * Should be greater than 0
         */
        imageStrokeColorWidth?: number
        /**
         * Album name to show
         */
        albumName?: string
        /**
         * How many columns in one row
         */
        columnCount?: number
        /**
         * Callback when image tapped
         */
        onTapImage?: (event: OnTapEvent) => void
        /**
         * Selected images (will show the selected badge)
         */
        selectedImages?: string[]
        selection?: Selection
        customButtonStyle?: CustomButtom
        /**
         * iOS only - On image tap return the image internal 
         * (tmp folder) uri (intead of Photos.framework asset id)
         */
        getUrlOnTapImage?: boolean
        /**
         * iOS only
         * On iOS images can be stored in iCould if the device is low on space which means 
         * full-resolution photos automatically replaced with optimized version and full 
         * resolution versions are stored in iCloud.
         * In this case, we need to download the image from iCloud and Photos Framework by 
         * Apple does a great job. Downloading take time and we deal with UI, 
         * so we need to show loading/progress indicator. In order to do so, 
         * we provide 3 types of loading/progress inidcators:
         * Sets remoteDownloadIndicatorType prop (and remoteDownloadIndicatorColor in order to sets the Color) 
         * on CameraKitGalleryView.
         * In order to simulate this loading behaviour, since reach low on storage situation is hard, 
         * add this prop iCloudDownloadSimulateTime={TIME_IN_SECONDS}, just DO NOT FORGET TO REMOVE IT.
         */
        remoteDownloadIndicatorType?: 'spinner' | 'progress-bar' | 'progress-pie'
        /**
         * iOS only - Color of the remote download indicator to show
         */
        remoteDownloadIndicatorColor?: Color
        /**
         * iOS only - Callback when the device curentlly 
         * download remote image stored in the iCloud.
         */
        onRemoteDownloadChanged?: () => void
    }


    export class CameraKitGalleryView extends React.Component<CameraKitGalleryViewProps> {
        constructor(props: CameraKitGalleryViewProps);
    }

    export type AlbumWithThumbnail = {
        albumName: string,
        imagesCount: number
        thumbUri: string
    }

    export interface CameraKitGalleryStatic {
        getAlbumsWithThumbnails(): Promise<{
            albums: AlbumWithThumbnail[]
        }>
    }
    export const CameraKitGallery: CameraKitGalleryStatic
    export type CameraKitGallery = CameraKitGalleryStatic

}
