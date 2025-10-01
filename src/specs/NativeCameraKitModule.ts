/**
 * TurboModule spec for the native camera module.
 *
 * @remarks
 * - This file defines the codegen contract for `RNCameraKitModule`.
 * - It is consumed by React Native's codegen to produce strongly typed JS↔native bindings.
 * - Most apps should prefer the high‑level {@link Camera} component and its ref API. The module
 *   is used internally by the platform wrappers in `src/Camera.ios.tsx` / `src/Camera.android.tsx`.
 * - Authorization helpers are implemented on iOS; on Android the JS wrapper throws `Not implemented`.
 *
 * @internal
 */
import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { Double, Int32, UnsafeObject } from 'react-native/Libraries/Types/CodegenTypes';

/**
 * Capture result returned by {@link Spec.capture}.
 *
 * @remarks
 * Mirrors the public `CaptureData` shape (see `src/types.ts`), but typed with codegen primitives.
 * - iOS: returns `size` in bytes; path is a `file://` URI under Caches.
 * - Android: may include `id`/`path`; URI can be `file://` or `content://`.
 */
type CaptureData = {
  /** Local URI of the captured image. */
  uri: string;
  /** File name without path. */
  name: string;
  /** Image height in pixels. */
  height: Int32;
  /** Image width in pixels. */
  width: Int32;
  /** Android only: MediaStore id when available. */
  id?: string;
  /** Android only: absolute path when available. */
  path?: string;
  /** iOS only: image size in bytes. */
  size?: Int32;
};

/**
 * Native camera module contract.
 *
 * @remarks
 * - `capture` requires a view tag referencing a mounted `CKCamera` view. The platform wrappers
 *   pass this automatically using `findNodeHandle` on the forwarded ref.
 * - Authorization helpers are implemented on iOS, and no‑ops on Android.
 */
export interface Spec extends TurboModule {
  /**
   * Capture a JPEG from the associated camera view.
   *
   * @param options - Reserved for future use.
   * @param tag - React tag for the native camera view (provided by wrappers).
   */
  capture(options?: UnsafeObject, tag?: Double): Promise<CaptureData>;

  /** Request camera permission (iOS only). */
  requestDeviceCameraAuthorization: () => Promise<boolean>;

  /** Check camera permission status (iOS only). */
  checkDeviceCameraAuthorizationStatus: () => Promise<boolean>;
}

/**
 * Enforcing handle to the native module.
 *
 * @internal Do not import directly; use high‑level wrappers in `src/Camera.*.tsx`.
 */
export default TurboModuleRegistry.getEnforcing<Spec>('RNCameraKitModule');
