import { lazy } from 'react';
import { Platform } from 'react-native';

/**
 * Cross‑platform camera component for React Native.
 *
 * @remarks
 * Renders a high‑performance preview with photo capture, pinch‑to‑zoom,
 * tap‑to‑focus (iOS), and optional barcode scanning. The implementation is
 * platform‑specific and lazy‑loaded (`Camera.ios.tsx` / `Camera.android.tsx`).
 * Configure via {@link CameraProps}. Access the imperative API via a `ref` of
 * type {@link CameraApi} for actions like {@link CameraApi.capture | capture()}.
 *
 * Key props:
 * - {@link CameraProps.cameraType | cameraType}: select front/back camera.
 * - {@link CameraProps.zoomMode | zoomMode}: enable pinch‑to‑zoom gesture.
 * - {@link CameraProps.zoom | zoom}: programmatic zoom control (omit when using pinch).
 * - {@link CameraProps.maxZoom | maxZoom}: cap the maximum zoom factor.
 * - {@link CameraProps.flashMode | flashMode} / {@link CameraProps.torchMode | torchMode}: control flash/torch.
 * - {@link CameraProps.scanBarcode | scanBarcode} + {@link CameraProps.onReadCode | onReadCode}: barcode scanning.
 *
 * @category Components
 *
 * @example Basic usage
 * ```tsx
 * import React, { useRef } from 'react';
 * import { Camera, type CameraApi } from 'react-native-camera-kit';
 * 
 * export function Example() {
 *   const ref = useRef<CameraApi>(null);
 *   return (
 *     <Camera
 *       ref={ref}
 *       style={{ flex: 1 }}
 *       cameraType="back"
 *       flashMode="auto"
 *       zoomMode="on"
 *       onZoom={(e) => console.log('zoom', e.nativeEvent.zoom)}
 *     />
 *   );
 * }
 * ```
 *
 * @example Capture a photo
 * ```tsx
 * const snap = async () => {
 *   const photo = await ref.current?.capture();
 *   console.log(photo?.uri);
 * };
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
 * @see {@link CameraProps} for available props
 * @see {@link CameraApi} for the imperative API
 * @see {@link Orientation} for orientation values in `onOrientationChange`
 */
const Camera = lazy(() =>
  Platform.OS === 'ios'
    ? import('./Camera.ios')
    : import('./Camera.android'),
);
export default Camera;
