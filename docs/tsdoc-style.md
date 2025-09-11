# TSDoc Style Guide (react-native-camera-kit)

Purpose: Make API docs consistent, complete, and TypeDoc-friendly so we can generate high‑quality site/Dash output.

Scope: Public TypeScript surface only (everything exported from `src`). Native spec files under `src/specs` are internal and should be tagged `@internal`.

## General Rules
- Audience: App developers using this library in React Native apps.
- Voice: Direct, actionable, present tense. Avoid “This function…”.
- One‑line summary first; end with a period.
- Expand with a short paragraph under `@remarks` when useful (behavior, caveats, platform notes).
- Prefer small, runnable `@example` blocks in TSX using functional components and `useRef`.
- Put platform constraints in remarks as “Platform: iOS” / “Platform: Android”.
- Use `@defaultValue` to document defaults (including sentinel `-1` used to represent “unset” due to RN Codegen limits).
- Use `@deprecated`, `@since`, and `@see` when applicable.
- Group with `@category` so TypeDoc sections are tidy: Components, Imperative API, Types, Enums, Events, Constants, Native Module.
- Mark non‑public items with `@internal`.

## Tag Cheat Sheet
- `@public` for exported APIs (optional; exported implies public, but keep it explicit on top‑level items).
- `@remarks` for nuanced behavior, platform notes, and warnings.
- `@example` for concise TS/TSX usage.
- `@param` and `@returns` for functions/methods.
- `@defaultValue` for props/parameters with defaults.
- `@see` to cross‑link related APIs or README sections.
- `@deprecated`, `@since` as needed.

## Component Props (interfaces)
Document each prop with a short summary, then specifics in remarks. Include platform and default when relevant.

Example pattern:

```ts
/**
 * Controls zoom. Higher values zoom in.
 *
 * @remarks
 * - Default optical baseline is `1.0` (wide‑angle).
 * - Platform: iOS, Android.
 * - If `zoomMode` is `on`, treat `zoom` as uncontrolled (omit or set to `undefined`).
 *
 * @defaultValue 1.0 (device‑dependent minimum may be < 1.0)
 * @example
 * ```tsx
 * const [zoom, setZoom] = useState(1.0);
 * <Camera
 *   zoom={zoom}
 *   onZoom={(e) => setZoom(e.nativeEvent.zoom)}
 * />
 * ```
 */
zoom?: number;
```

Event props should describe the `nativeEvent` shape explicitly (even if typed) and when they fire.

## Imperative API (component ref)
Each method gets a clear contract, return type details, and file URL behavior.

```ts
/**
 * Capture a JPEG and return file info.
 *
 * @remarks
 * - Returns a `file://` URI where supported; always a URI string for consistency.
 * - Move the file to a permanent location if you need it beyond the current session.
 * - Platform: iOS, Android.
 *
 * @returns Promise with `{ uri, name, width, height, size? }`.
 * @see README: Imperative API › capture()
 */
capture(): Promise<CaptureData>;
```

## Enums, Types, Constants
- Enums: add a brief description for the enum and each member.
- String‑literal unions: summarize allowed values where they are used.
- Constants (e.g., `Orientation`): describe mapping and origin (native constants).

## Platform Nuances to Capture
- Optional numeric props normalized to `-1` before passing to native (RN Codegen limitation). Document this under each affected prop with `@remarks` and `@defaultValue -1 (treated as unset)` when appropriate.
- Color props on Android are run through `processColor`.
- iOS exposes `requestDeviceCameraAuthorization` and `checkDeviceCameraAuthorizationStatus` on the ref; Android throws “Not implemented”. Mark with platform notes.

## Examples — Canonical Snippets
Use concise TSX with hooks; show imports and refs.

```tsx
import React, { useRef } from 'react';
import { Button } from 'react-native';
import { Camera, type CameraApi } from 'react-native-camera-kit';

export function CaptureExample() {
  const ref = useRef<CameraApi>(null);
  return (
    <>
      <Camera ref={ref} zoomMode="on" />
      <Button title="Snap" onPress={async () => {
        const photo = await ref.current?.capture();
        console.log(photo?.uri);
      }} />
    </>
  );
}
```

## Writing Style Notes
- Sentence case; keep summaries ≤ 120 characters when possible.
- Prefer active voice, avoid repetition of type names (“Returns a promise” vs “This method returns…”).
- Keep examples minimal; highlight just one concept per example.
- When in doubt, favor clarity over cleverness.

