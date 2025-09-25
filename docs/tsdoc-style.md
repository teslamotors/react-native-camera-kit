# TSDoc Style Guide — react-native-camera-kit

This project uses TSDoc + TypeDoc to generate API docs. Follow these rules to keep docs consistent and useful.

## Principles

- Write for users of the library, not its implementation.
- Prefer examples over prose; keep examples runnable and minimal.
- Document the “why” when behavior is surprising or platform‑specific.

## Tag Cheat Sheet

- Summary: 1–2 lines. Imperative description (“Capture a photo.”).
- `@remarks`: Deeper context, platform notes, caveats. Prefix with “Platform: iOS/Android” when applicable.
- `@example`: Fenced code blocks (TS/TSX) with a concise scenario.
- `@defaultValue`: Always tag defaults, including sentinel `-1 (treated as unset)` when relevant.
- `@deprecated`, `@since`, `@see`: Use when linking related APIs or migration targets helps scanning.
- `@internal`: Hide from docs when not part of the public surface.
- `@category`: Use one of: Components, Types, Enums, Events, Constants, Utils.

## Components

For component wrappers (e.g., `Camera`):

```
/**
 * Camera component (Fabric view wrapper).
 *
 * @remarks Exposes a capture API via ref; props are declarative.
 * @example Basic usage
 * ```tsx
 * <Camera style={{ flex: 1 }} />
 * ```
 * @category Components
 */
```

## Props Interfaces

```
/**
 * Props for the `Camera` component.
 * @remarks
 * - Optional numeric props use the sentinel `-1` for RN Codegen.
 * - Controlled vs uncontrolled: when `zoom` is set, pinch does not change zoom; when `zoom` is `undefined` and `zoomMode='on'`, pinch adjusts zoom and emits onZoom.
 * @noInheritDoc
 */
export interface CameraProps extends ViewProps {
  /** Enable or disable the pinch gesture handler. @defaultValue 'on' */
  zoomMode?: ZoomMode;
  /** Controls zoom. Higher values zoom in. @defaultValue 1.0 */
  zoom?: number;
}
```

## Types and Enums

Add a one‑liner summary for each; include sample values or mapping where useful.

```
/** Lens facing direction. */
export enum CameraType { Front = 'front', Back = 'back' }
```

## Platform Notes

- Mark iOS‑only / Android‑only props in the doc comment.
- Mention color conversions (`processColor`) and numeric sentinel behavior.
- When describing behavior, verify against the native codepaths:
  - iOS: AVFoundation (Swift/ObjC++): zoom normalization, focus timers, torch persistence, orientation events.
  - Android: CameraX + ML Kit: zoom ratios, focus metering, Surface rotation mapping, scan throttling.

## Controlled vs Uncontrolled Props

Explain both models when a prop can be driven by user gestures and by code. Document how events behave to avoid feedback loops.

```
// Controlled zoom (pinch does not change zoom)
const [zoom, setZoom] = useState(1.0);
<Camera zoomMode="on" zoom={zoom} onZoom={e => setZoom(e.nativeEvent.zoom)} />

// Uncontrolled zoom (pinch updates zoom and emits onZoom)
<Camera zoomMode="on" zoom={undefined} onZoom={e => console.log(e.nativeEvent.zoom)} />
```

## Don’ts

- Don’t duplicate React Native’s `ViewProps` docs.
- Don’t leak internal implementation details that don’t affect behavior.
