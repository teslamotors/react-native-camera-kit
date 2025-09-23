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
 * @category Components
 */
const Camera = lazy(() =>
  Platform.OS === 'ios'
    ? import('./Camera.ios')
    : import('./Camera.android'),
);

export default Camera;
