# TSDoc Style Guide — react-native-camera-kit

This project uses TSDoc + TypeDoc to generate API docs. Follow these rules to keep docs consistent and useful.

## Principles

- Write for users of the library, not its implementation.
- Prefer examples over prose; keep examples runnable and minimal.
- Document the “why” when behavior is surprising or platform-specific.

## Blocks and Tags

- Summary: 1–2 lines. Starts with an imperative description.
- `@remarks`: Deeper context, platform notes, caveats.
- `@example`: Use fenced code blocks with a short title (optional).
- `@deprecated`: Include migration notes.
- `@internal`: Hide from docs.
- `@category`: One of: Components, Types, Enums, Constants, Utils.

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
 * @remarks Use numeric `-1` sentinels for optional RN Codegen props.
 * @noInheritDoc
 */
export interface CameraProps extends ViewProps {
  /** Enable or disable the pinch gesture handler. */
  zoomMode?: ZoomMode;
  /** Controls zoom. Higher values zoom in. Default is `1.0`. */
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

## Don’ts

- Don’t duplicate React Native’s `ViewProps` docs.
- Don’t leak internal implementation details in public docs.

