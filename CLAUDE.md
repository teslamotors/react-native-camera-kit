# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

React Native Camera Kit is a high-performance, cross-platform camera library for React Native applications (iOS and Android). It provides:
- Photo capture with high performance optimization
- Barcode/QR code scanning capabilities
- Camera preview support (including iOS simulator)
- Extensive camera control options (flash, focus, zoom, torch)
- Device orientation detection

This is a native library that uses React Native Codegen for cross-platform native module bindings.

## Architecture

### JavaScript/TypeScript Layer (`src/`)

The TypeScript codebase provides the React wrapper and type definitions:

- **Entry point** (`src/index.ts`): Exports the Camera component, types, and Orientation constants
- **Camera component** (`src/Camera.tsx`): Platform-agnostic wrapper that lazy-loads platform-specific implementations
  - `src/Camera.ios.tsx`: iOS-specific camera component
  - `src/Camera.android.tsx`: Android-specific camera component
- **Types and props**:
  - `src/types.ts`: Core type definitions (CameraType, CodeFormat, TorchMode, FlashMode, FocusMode, ZoomMode, ResizeMode, CameraApi, CaptureData)
  - `src/CameraProps.ts`: Complete Camera component props interface (both platform-specific and shared)
- **Native specs** (`src/specs/`):
  - `CameraNativeComponent.ts`: React Native Codegen definition for the camera view component (NativeProps)
  - `NativeCameraKitModule.ts`: TurboModule specification for native camera functions (capture, authorization)

**Key Pattern**: Optional numeric props are represented as `-1` or `undefined` until React Native Fabric supports optional values. Both platform-specific implementations handle this conversion.

### Native Layer

- **iOS** (`ios/ReactNativeCameraKit/`): Swift implementation
  - `RealCamera.swift` / `SimulatorCamera.swift`: Core camera implementation (real and simulator)
  - `CameraManager.swift`: Manages camera state and configuration
  - `PhotoCaptureDelegate.swift`: Handles photo capture logic
  - `ScannerInterfaceView.swift` / `ScannerFrameView.swift`: Barcode scanning UI
  - `RatioOverlayView.swift`: Aspect ratio guide overlay

- **Android** (`android/src/main/java/com/rncamerakit/`): Kotlin implementation
  - `CKCamera.kt`: Main camera view component
  - `QRCodeAnalyzer.kt`: Barcode scanning using CameraX
  - Event classes in `events/`: Handle camera callbacks (zoom, orientation, errors, etc.)
  - Platform-specific code split between `newarch/` (React Native 0.73+, Fabric) and `oldarch/` (legacy)

## Development Commands

### Build and Compilation

```bash
# Build TypeScript to JavaScript (outputs to dist/)
yarn build

# Clean build artifacts
yarn clean

# Run both clean and build
yarn clean && yarn build
```

### Linting and Code Quality

```bash
# Run ESLint
yarn lint

# ESLint rules are configured in .eslintrc.js with:
# - Max line length: 120 characters
# - Required semicolons, proper indentation (2 spaces)
# - No console.log or debugger statements allowed
# - Strict import resolution checking
```

### Testing

```bash
# Run all tests
yarn test

# Run tests for a specific file
yarn test -- src/__tests__/index.test.tsx

# The project uses Jest with minimal test configuration
# Tests should be placed in __tests__ directories
```

### Example Project

```bash
# Bootstrap the example app (installs dependencies and pods)
yarn bootstrap

# For Linux:
yarn bootstrap-linux
```

## Key Development Notes

### Native Component Integration

The camera component uses **React Native Codegen** to auto-generate native binding code:
- Props are defined in `src/specs/CameraNativeComponent.ts` (NativeProps interface)
- Changes to props require running: `yarn codegen` (generates `build/` directory)
- The codegen config is in `package.json` under `codegenConfig`

### Platform-Specific Code

The library uses React Native's platform module for loading platform-specific implementations:
```typescript
// In src/Camera.tsx
const Camera = lazy(() =>
  Platform.OS === 'ios'
    ? import('./Camera.ios')
    : import('./Camera.android'),
);
```

Both implementations handle color props differently:
- **Android**: Uses `processColor()` to convert color values
- **iOS**: Passes colors as-is

### Optional Props Pattern

React Native Codegen doesn't support optional numeric props, so:
- Numeric props default to `-1` to indicate "undefined"
- The native layer interprets `-1` as "no value provided"
- This affects: `zoom`, `maxZoom`, `scanThrottleDelay`, `resetFocusTimeout`, `shutterAnimationDuration`

### Type System

The project uses strict TypeScript (`strict: true` in tsconfig.json):
- `@ts-expect-error` comments are used for Codegen type mismatches (see Camera.ios.tsx line 33)
- Type definitions must be accurate between user-facing types and native specs
- All numeric types from Codegen props must be converted in both platform files

## Testing and Releases

### Running Tests

```bash
# Run Jest tests
yarn test

# Build TypeScript (validates code)
yarn build

# Test files follow Jest conventions and are excluded from build (tsconfig.json excludes *.test.tsx)
```

### Release Process

```bash
# Standard npm release
yarn release

# Beta release
yarn release:beta

# Local testing (creates and opens tar.gz)
yarn release:local
```

The library is published to npm as `react-native-camera-kit` with the `files` array in package.json controlling what gets included in the published bundle.

## Important Configuration Details

- **TypeScript**: Strict mode enabled, targets ESNext, outputs to `dist/` with declaration files
- **Package managers**: Yarn 1.22.22 required (specified in package.json engines)
- **Node**: Requires Node.js >= 18
- **React Native**: Uses version 0.79.0, supports both legacy and new architecture (Fabric)
- **Import resolution**: ESLint is configured to recognize `.ios.tsx`, `.android.tsx`, and `.js` platform variants

---

## Camera Kit Sync State

**Last synchronized upstream commit**: 8e5149a6e6d3902ae87dad50da0d06ec2c61d2b8
**Upstream version**: 17.0.1
**Fork version**: 17.0.1
**Last sync date**: 2026-01-17
**Sync status**: success

### Changes Synced (upstream v16.2.0 -> v17.0.1)

**Key changes from upstream**:
- Replaced `iOsSleepBeforeStarting` (Int) with `iOsDeferredStart` (Bool) for iOS camera startup optimization
- iOS 26+ deferred start support via `AVCaptureOutput.deferredStartEnabled`
- Improved stress test logging with elapsed time tracking
- Various iOS formatting and code organization improvements

**Files synced (16 files)**:
- All iOS Swift files (CameraView.swift, RealCamera.swift, SimulatorCamera.swift, CameraProtocol.swift)
- CKCameraViewComponentView.mm (Objective-C++ bridge)
- TypeScript layer (Camera.ios.tsx, CameraProps.ts, CameraNativeComponent.ts)
- Example app improvements (App.tsx, BarcodeScreenExample.tsx)
- README.md with updated props documentation

### Fork-Specific Code Preserved

All QR-only Android architecture preserved:
- `android/build.gradle` - Uses `implementation 'com.github.limpbrains:qr:v0.0.3'`
- `android/src/main/java/com/rncamerakit/QRCodeAnalyzer.kt` - Uses `QRDecoder.decode()` from limpbrains/qr
- `android/src/main/java/com/rncamerakit/CodeFormat.kt` - Simplified enum (no ML Kit conversions)
- `android/src/main/java/com/rncamerakit/CKCamera.kt` - String callback `onQRCodeDetected(String)`

### Validation

- `yarn build` - PASSED
- `yarn lint` - PASSED
- `yarn test` - PASSED
- No `google.mlkit` references in android/ - VERIFIED
- `limpbrains/qr` dependency present - VERIFIED
- `QRDecoder.decode()` preserved - VERIFIED
