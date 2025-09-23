import { lazy } from 'react';
import { Platform } from 'react-native';

/**
 * Camera component (Fabric view wrapper).
 *
 * Renders the live camera preview with props/events and exposes an
 * imperative capture API via ref.
 *
 * - Props: {@link CameraProps}
 * - Ref API: {@link CameraApi}
 * - Platforms: iOS and Android (lazy‑loaded per platform)
 *
 * Common props:
 * - {@link CameraProps.cameraType | cameraType}: select front/back camera
 * - {@link CameraProps.zoomMode | zoomMode} + {@link CameraProps.zoom | zoom}: gesture vs programmatic zoom
 * - {@link CameraProps.maxZoom | maxZoom}: cap the maximum zoom factor
 * - {@link CameraProps.flashMode | flashMode} vs {@link CameraProps.torchMode | torchMode}
 * - {@link CameraProps.scanBarcode | scanBarcode} + {@link CameraProps.onReadCode | onReadCode}
 *
 * @example Basic usage
 * ```tsx
 * import { Camera } from 'react-native-camera-kit';
 *
 * export function Preview() {
 *   return <Camera style={{ flex: 1 }} />;
 * }
 * ```
 *
 * @example Capture a photo
 * ```tsx
 * import React, { useRef } from 'react';
 * import { Camera, type CameraApi } from 'react-native-camera-kit';
 *
 * export function Snapper() {
 *   const ref = useRef<CameraApi>(null);
 *   return (
 *     <>
 *       <Camera ref={ref} style={{ flex: 1 }} />
 *       <Button title="Snap" onPress={async () => {
 *         const photo = await ref.current?.capture();
 *         console.log(photo?.uri);
 *       }} />
 *     </>
 *   );
 * }
 * ```
 *
 * @example Barcode scanning
 * ```tsx
 * <Camera
 *   scanBarcode
 *   showFrame
 *   onReadCode={(e) => {
 *     console.log('barcode', e.nativeEvent.codeStringValue, e.nativeEvent.codeFormat);
 *   }}
 * />
 * ```
 *
 * @category Components
 */
const Camera = lazy(() =>
  Platform.OS === 'ios'
    ? import('./Camera.ios')
    : import('./Camera.android'),
);

export default Camera;
