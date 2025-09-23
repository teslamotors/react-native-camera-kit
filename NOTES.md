2025-09-22 19:00 UTC

# React Native Camera Kit — Initial Recon

Scope: Familiarize with repo structure, build/test tooling, JS/TS surface area, and native iOS/Android implementations. Capture decisions, gotchas, and pointers for future work.

## Top-Level Overview

- Package: `react-native-camera-kit` v16.1.2 (MIT). Monorepo contains library, native code, and example app.
- Platforms: iOS (Swift + ObjC++) and Android (Kotlin, CameraX + ML Kit for barcodes). RN new architecture support (TurboModule + Fabric component).
- Key dirs:
  - `src/` — TS/TSX public API and platform split components.
  - `ios/ReactNativeCameraKit/` — iOS native view/module + Swift implementation.
  - `android/src/...` — Android native view (`CKCamera`) and module (`RNCameraKitModule`).
  - `example/` — Minimal example screens for camera and barcode.
  - `docs/` — Typedoc + Dash docset tooling and CI workflow.
  - `images/` — README screenshots and example assets.
  - `scripts/` — typedoc post-processing, docset builder, simple SwiftLint check.

## Tooling / Scripts

- Node ≥ 18; `yarn@1.22.22`.
- Build: `yarn build` compiles TS to `dist/` (entry `dist/index.js`, types `dist/index.d.ts`).
- Docs:
  - `yarn docs:build` → generates Typedoc site under `docs/site` and post-processes.
  - `yarn docs:serve` → static server for docs (port via `DOCS_PORT`).
  - `yarn docset:build` → builds Dash docset at `docs/react-native-camera-kit.docset`.
- Release: `yarn release` / `release:beta` / `release:local`.
- Codegen: `yarn codegen` runs RN codegen for both platforms from `src/specs`.
- Example bootstrap: `yarn bootstrap` (iOS uses Bundler + CocoaPods; Linux variant available).
- Lint: ESLint/Prettier; iOS `scripts/check-ios.sh` runs SwiftLint if installed (see `Brewfile`).

## RN Integration Metadata

- `package.json`:
  - `react-native`: `src/index` (uses platform-specific `Camera.*.tsx`).
  - `codegenConfig`:
    - Name: `NativeCameraKitSpec` (type: `all`).
    - JS sources: `src/specs/`.
    - Android: `javaPackageName: com.rncamerakit`.
    - iOS: component provider maps `CKCamera` → `CKCameraViewComponentView`.
- `ReactNativeCameraKit.podspec`:
  - iOS min `15.0`.
  - Sources include Swift/ObjC++ from `ios/ReactNativeCameraKit` and generated specs from `ios/generated/rncamerakit_specs`.
  - Supports `USE_FRAMEWORKS` flag.
- `react-native.config.js`: minimal, no special Android config beyond default.

## Public JS/TS Surface

- Main entry `src/index.ts`:
  - Exports `Camera` (lazy, platform-split), enums/types (e.g., `CameraType`, `TorchMode`, `FlashMode`, `ResizeMode`), and `Orientation` constants mapping to native orientation integers (0..3).
  - Default export is low-level `NativeModules.CameraKit` (not recommended for direct use).
- Component definition `src/Camera.tsx` uses `React.lazy` to import `Camera.ios.tsx` or `Camera.android.tsx`.
- Props `src/CameraProps.ts`:
  - Cross‑platform: `flashMode`, `focusMode`, `zoomMode`, `zoom`, `maxZoom`, `torchMode`, `cameraType`, `onOrientationChange`, `onZoom`, `scanBarcode`, `showFrame`, `laserColor`, `frameColor`, `barcodeFrameSize`, `onReadCode`, `scanThrottleDelay`, `onCaptureButtonPressIn/Out`.
  - iOS‑only: `ratioOverlay`, `ratioOverlayColor`, `resetFocusTimeout`, `resetFocusWhenMotionDetected`, `resizeMode`, `maxPhotoQualityPrioritization`.
  - Android‑only: `shutterPhotoSound`.
  - Notes: Several numeric props normalized to `-1` due to RN Codegen optional limitations.
- Imperative API `CameraApi` (via `ref`):
  - `capture(): Promise<CaptureData>`; iOS returns `size` in bytes; Android returns additional `id`/`path` sometimes.
  - iOS‑only: `requestDeviceCameraAuthorization()`, `checkDeviceCameraAuthorizationStatus()`; on Android these throw `Not implemented` from JS wrapper.

## iOS Native (Swift/ObjC++)

- View class `CKCameraViewComponentView.mm` (Fabric) wraps Swift `CKCameraView` content view; translates props/events between RN and native. Disables recycling; manages event emitters for `onReadCode`, `onOrientationChange`, `onZoom`, `onCaptureButtonPress*`.
- Module `RNCameraKitModule.mm` exposes TurboModule methods and resolves view instances by reactTag to call into manager.
- Swift `CameraView.swift` coordinates:
  - Permissions flow (iOS + macCatalyst specifics).
  - Subviews: live preview, scanner overlay (`ScannerInterfaceView`), focus UI, optional ratio overlay.
  - Gestures: pinch‑to‑zoom; tap‑to‑focus (via `FocusInterfaceView`).
  - Orientation events; shutter flash animation; saving captured JPEG to caches under a namespaced folder for stability (works well with Expo FS).
  - Barcode scanning throttling via `scanThrottleDelay` (ms).
  - iOS 17.2+ hardware capture/volume button interactions → `onCaptureButtonPressIn/Out`.
- Swift types: `CameraProtocol` with `RealCamera` and `SimulatorCamera`, `PhotoCaptureDelegate`, `CodeFormat`, etc. AVFoundation for camera pipeline.

## Android Native (Kotlin)

- Package class `RNCameraKitPackage` wires view manager and module.
- New Arch module `RNCameraKitModule` implements codegen spec; `capture(options, tag)` resolves view and calls `CKCamera.capture(...)`. Authorization stubs are no‑ops (handled by user via `react-native-permissions`). Provides orientation constants (0..3) for parity.
- View manager `CKCameraManager` (codegen delegate):
  - Maps props to `CKCamera` methods; converts colors and sizes; exports direct events for orientation, read code, picture taken, zoom, error, capture button.
  - Android‑only props: `outputPath`, `shutterAnimationDuration`, `shutterPhotoSound` (non‑public in JS props except `shutterPhotoSound`).
- View `CKCamera`:
  - CameraX: `Preview`, `ImageCapture`, `ImageAnalysis` (for ML Kit barcode analyzer when enabled).
  - Handles permissions request if missing (CAMERA), orientation listener maps to RN `Orientation` values, pinch‑to‑zoom with guard when `zoom` is controlled.
  - Emits events via `UIManagerHelper` with surfaceId/viewId.
  - Barcode frame overlay with configurable colors and size; throttling via `scanThrottleDelay`.
  - Shutter effect overlay + optional `MediaActionSound` sound.
  - Key gotcha: must rebind use cases when certain props change (e.g., `scanBarcode`, lens facing) — code already handles rebinding.

## Example App

- `example/src/CameraExample.tsx` shows photo capture, zoom interactions, torch/flash modes, resize toggling, and handling orientation changes by counter‑rotating UI.
- `example/src/BarcodeScreenExample.tsx` demonstrates barcode scanning with throttling, frame overlay, and haptics.
- iOS example targets via Xcode project under `example/ios`; Android example manifests present.

## Docs / CI

- README documents install, permissions (explicitly defers to `react-native-permissions`), imperative API, Expo plugin compatibility, and doc building.
- GitHub Actions workflow for docset packaging under `docs/.github/workflows/docset.yml` (artifacts on PRs/push; releases attach `.docset`).

## Notable Design Choices / Constraints

- RN New Architecture first‑class: codegen specs at `src/specs/*` define both Fabric view (`CKCamera`) and TurboModule (`RNCameraKitModule`). JS props adapt around codegen’s current optional prop limitations by sending `-1` for unset numerics.
- iOS minimum iOS 15; macCatalyst supported with specific permission logic and front camera defaulting during setup.
- Android relies on CameraX and ML Kit barcode scanning; permissions intentionally excluded from module API to avoid duplicating complex UX flows — consumers must use a dedicated permissions lib.

## Potential Developer Gotchas

- Must prompt for permissions before rendering `Camera` or the preview appears black.
- When `zoomMode` is `on`, avoid passing a concrete `zoom` value unless controlling it manually; otherwise pinch gestures may fight a controlled prop. Suggested patterns are documented in `CameraProps`.
- Some props are platform‑specific; be careful to guard or split code when targeting both.
- On Android, changing scan‑related props may cause camera use‑case rebinds; ensure UI can handle brief preview interruptions.
- Doc building scripts assume Typedoc v0.28+ and Node 18; Dash docset build uses macOS tooling.

## Quick API Map

- Component: `<Camera {...props} ref={ref} />`
- Ref methods: `capture()`, `requestDeviceCameraAuthorization()` (iOS), `checkDeviceCameraAuthorizationStatus()` (iOS).
- Events: `onOrientationChange`, `onZoom`, `onReadCode`, `onError`, `onCaptureButtonPressIn/Out`.

## Next Exploration Ideas

- Run `yarn codegen` and verify generated artifacts are present/ignored correctly (iOS `ios/generated/rncamerakit_specs`, Android build output only).
- Build the example app on both platforms; measure capture latency with `maxPhotoQualityPrioritization` values.
- Investigate adding video capture in future (currently stills + barcode only).

2025-09-22 16:45 UTC

- Wrote FABRIC_VIEW_COMPONENTS.md detailing the New Architecture Fabric view component: codegen spec, iOS/Android bindings, events, lifecycle, and extension steps.
- Verified code paths and references with ripgrep; noted optional-numeric sentinel pattern and componentProvider mapping.

2025-09-22 16:58 UTC

- Added FABRIC_COMPONENTS.md with architecture diagrams, sequence diagrams, and end-to-end examples (adding props/events, capture flow, enabling New Arch).
- Linked the broader doc from FABRIC_VIEW_COMPONENTS.md and added a host-view data-flow diagram.

2025-09-22 17:04 UTC

- Expanded New Arch docs with FAQs, Good/Bad practices, and Common Mistakes sections.
- Centralized guidance in FABRIC_COMPONENTS.md and added view-specific FAQs/practices to FABRIC_VIEW_COMPONENTS.md.

2025-09-22 17:15 UTC

- Created a minimal New Architecture sample under `new-arch-minimal/` with:
  - `src/specs/DemoViewNativeComponent.ts` (Fabric host view spec)
  - `src/specs/DemoTurboModule.ts` (TurboModule spec)
  - `src/DemoView.tsx`, `src/App.tsx` (JS wrapper and demo screen)
  - `new-arch-minimal/package.json` with `codegenConfig` (name: DemoSpec) and a local `yarn codegen` script.
- Added root script `yarn codegen:demo` to generate native artifacts for the demo.
- Ran codegen:
  - iOS output at `new-arch-minimal/build/generated/ios` (Props.h, EventEmitters.h, ComponentDescriptors.h/mm, JSI bindings).
  - Android output at `new-arch-minimal/android/app/build/generated/source/codegen` (view manager interface/delegate, JNI sources, component descriptors).
  - Observed post-generation CLI error: `TypeError [ERR_INVALID_ARG_TYPE]: The "from" argument must be of type string. Received undefined` after successful artifact generation (likely RN CLI copy step regression). Artifacts are present and usable.
- Reflection:
  - Codegen works fine when pointed at a folder with its own `codegenConfig`; generation does not require modifying the main library’s specs.
  - The sentinel `-1` pattern for optional numerics in the demo matches our library’s approach and is validated by the generated Props.
  - For a complete runnable native demo, we’d add minimal native files: Fabric component view on iOS and a Kotlin view manager/view on Android, or integrate the demo into the existing library packages. Left as optional to avoid bloating the core podspec/gradle.
- Next steps (optional):
  - Provide minimal native implementations (iOS `DemoViewComponentView.mm` + Swift view; Android `DemoViewManager.kt` + `DemoView.kt`, `DemoModule.kt`) and register in the library packages for an end-to-end runnable demo inside the example app.
2025-09-22 17:36 UTC

- Added minimal native stubs for demo: iOS Fabric component view + Swift view + TurboModule; Android view/manager/module/package under new-arch-minimal/.
- Ran codegen previously; validated iOS and Android generated artifacts exist.
- Documented integration steps and caveats in new-arch-minimal/README.md.

2025-09-22 18:02 UTC

- Wired the demo into the example app:
  - iOS: Podfile enables New Arch, runs codegen:demo pre-install, and adds DemoNewArchMinimal pod. Added experimental SPM package template.
  - Android: sourceSets include demo sources and generated interfaces; MainApplication registers DemoPackage.
  - JS: added DemoNewArchExample screen and menu entry.
- Wrote docs/NEW_ARCH_DEMO_WIRING.md with step-by-step build/run instructions and SPM notes.

2025-09-22 18:25 UTC

- Researched the local React Native monorepo at `/Users/gaston/Projects/tesla/react-native` (HEAD 57a1820c853 on main) to ground our New Architecture docs in upstream sources.
- Key confirmations from source:
  - Fabric detection: `global.nativeFabricUIManager` presence with caching proxy implemented in `packages/react-native/Libraries/ReactNative/FabricUIManager.js`.
  - iOS component registration: Fabric views implement `+componentDescriptorProvider` returning `concreteComponentDescriptorProvider<...>`; see `packages/react-native/React/Fabric/Mounting/ComponentViews/View/RCTViewComponentView.mm:125` and patterns across core components.
  - iOS build flag: `packages/react-native/scripts/cocoapods/new_architecture.rb` injects `-DRCT_NEW_ARCH_ENABLED=1` and Swift flags when New Arch is on.
  - TurboModule resolution on JS: `Libraries/TurboModule/TurboModuleRegistry.js` uses `global.__turboModuleProxy` with fallbacks to legacy `NativeModules` under certain interop flags.
  - Codegen utility discovery: `packages/react-native/scripts/codegen/codegen-utils.js` tries monorepo `packages/react-native-codegen` first, falls back to `@react-native/codegen` from node_modules.
  - WithDefault defaults: RN’s generated d.ts and Android tests show sentinel defaults via `WithDefault<...>` and ReactProp default values; validates our `-1` optional numeric pattern for view props.
- Updated docs:
  - `FABRIC_COMPONENTS.md`: added “Notes grounded in RN source tree”: Fabric manager detection, iOS provider method, build flags, TM registry, codegen utils.
  - `FABRIC_VIEW_COMPONENTS.md`: added grounding section and references to upstream files.
  - `docs/NEW_ARCH_DEMO_WIRING.md`: annotated RN CLI/codegen behavior and fallbacks.
2025-09-22 18:35 UTC

- Completed New Architecture readiness review. Added NEW_ARCH_REVIEW.md with findings and actionable recommendations.
- Key issues: JS permission request bug on iOS; misnamed default export; optional old-arch parity for iOS permission helpers; Podspec glob cleanup; README polish.
- Validated codegen outputs and matched class/protocol names to native code; cross-checked RN upstream for correctness.

2025-09-23 00:14 UTC

- Added proposals for next review items:
  - docs/PROPOSAL-readme-new-arch-section.md (README New Arch section draft).
  - docs/PROPOSAL-android-permissions-and-manifest.md (Android permission alignment).
  - docs/PROPOSAL-orientation-constants.md (centralize Orientation constants).
  - docs/PROPOSAL-capture-options-refactor.md (move Android outputPath to capture options).
  - docs/PROPOSAL-ci-new-arch-matrix.md (CI matrix for New/Old Arch on Android/iOS).
- All proposals are review-only; no code changes applied, per plan.

2025-09-23 00:16 UTC

- Added proposals for deeper review (no implementation):
  - docs/PROPOSAL-optional-numeric-props-and-codegen.md (sentinels -1, migration plan).
  - docs/PROPOSAL-error-events-and-codes.md (standardize onError codes, surface missing permission).
- All changes are docs-only to support design review before coding.

2025-09-23 00:20 UTC

- Added proposal: docs/PROPOSAL-android-capture-metadata.md (fix width/height, handle content URIs, deprecate id/path).
- Focus: correctness and stability of Android capture results in New Arch context.

2025-09-23 00:39 UTC

- Added proposal: docs/PROPOSAL-barcode-payload-and-format.md (unified format + optional bounds/cornerPoints).
- Focus: cross-platform payload consistency and overlay-ready coordinates.

2025-09-23 00:42 UTC

- Added proposal: docs/PROPOSAL-package-exports-and-entrypoints.md (exports map, sideEffects, files).
- Goal: strengthen module resolution for RN vs Node/bundlers and prevent deep-imports.

2025-09-23 00:50 UTC

- Re-read RN New Architecture research (all chapters) at /Users/gaston/Projects/tesla/react-native/react-native-new-arch-research/.
- Key reinforced takeaways for our library:
  * Prefer TurboModule spec accessors over NativeModules; bridgeless-friendly.
  * Fabric component views must source props via codegen; optional numerics workaround remains (-1).
  * Events via codegen emitters; error taxonomy helps app DX.
  * Avoid vendoring codegen; rely on RN pods; use install_modules_dependencies.
  * CI should validate both arch modes; codegen pitfalls noted.
  * Permissions are app UX; libraries should avoid auto prompts.
  * Orientation/constants should be single-sourced from native when possible.
- Our open proposals align with these guidelines; next reviews will continue to reflect RN best practices.

2025-09-23 00:52 UTC

- Re-read and incorporated full RN New Architecture research (all 17 markdown files) at /Users/gaston/Projects/tesla/react-native/react-native-new-arch-research/.
- Will align all further proposals and reviews to this research as the authoritative guidance.

2025-09-23 01:09 UTC

- Added docs/PROPOSAL-new-arch-tightening.md consolidating latest New Arch findings:
  * iOS JSI signature validation steps
  * Barcode format naming mismatch (itf vs itf-14)
  * Android maxZoom default (-1 sentinel)
  * iOS capture options behavior
  * (Tracks default export correction proposal)

2025-09-23 03:50 UTC

- Consolidated reviews into NEW_ARCH_REVIEW_3.md and removed superseded NEW_ARCH_REVIEW.md / NEW_ARCH_REVIEW_2.md.
- NEW_ARCH_REVIEW_3.md lists Must/Should/Could fixes with evidence, files, and references to proposal docs.

2025-09-23 03:57 UTC

- Added migration planning:
  * NEW_ARCH_REVIEW_3.md: Migration Guide (draft outline) section.
  * docs/PROPOSAL-migration-guide.md with before/after code, deprecations, timelines, RN version range.

2025-09-23 04:52

- Start session. Setting up notes and plan.

$now

- Scanned repo: found FABRIC_COMPONENTS.md and FABRIC_VIEW_COMPONENTS.md at root; no `docs/` merged versions yet.
- Located docset artifacts and mentions:
  * docs/react-native-camera-kit.docset (to be removed)
  * docs/site/index.html contains a "Documentation and Dash Docset" section (to prune)
  * PR.md includes extensive docset pipeline sections (to rewrite to TSDoc/TypeDoc only)
  * docs/PROPOSAL-ci-new-arch-matrix.md and docs/PROPOSAL-codegen-practices-and-guardrails.md mention optional docset (to adjust)
- No package.json `docset:*` scripts present; no scripts/build-docset.mjs in repo.
- Plan:
  1) Merge + rewrite the two FABRIC docs into `docs/FABRIC.md` (single source of truth)
  2) Add stub pointers in root FABRIC_*.md files to avoid duplication
  3) Remove `docs/react-native-camera-kit.docset` dir and scrub docset mentions (PR/proposals/site)
  4) Keep/lean into TypeDoc/TSDoc only; do not alter build tooling otherwise.

$now

- Merged `FABRIC_COMPONENTS.md` + `FABRIC_VIEW_COMPONENTS.md` into `docs/FABRIC.md` (single source of truth).
- Converted both original files into short stubs pointing to `docs/FABRIC.md` (avoid duplication).
- Removed `docs/react-native-camera-kit.docset` directory.
- Scrubbed docset mentions:
  * PR.md: removed Dash docset content; CI now references TypeDoc only.
  * docs/PROPOSAL-ci-new-arch-matrix.md: removed optional docset job and wording.
  * docs/PROPOSAL-codegen-practices-and-guardrails.md: removed `.docset` mention.
  * docs/site/index.html: replaced section with a simple “Documentation” (TypeDoc) instructions; left sidebar anchor benign.

$now

- Reworked consolidation per request: created `docs/REACT_NATIVE_NEW_ARCH.md` with a full merge of Fabric view + TurboModule docs, sequence diagrams, props/events, codegen, platform specifics, extension checklist, and best practices.
- Removed previous `docs/FABRIC.md` and deleted old root docs: `FABRIC_COMPONENTS.md`, `FABRIC_VIEW_COMPONENTS.md`.
- Cross-checked content against repo sources (`src/specs/*`, iOS/Android native files) and internal research folder `/Users/gaston/Projects/tesla/react-native/react-native-new-arch-research/*` to ensure terminology and coverage (Fabric view components + TurboModules).
- Updated `new-arch-minimal/README.md` to point to the new consolidated doc.
- Note: TypeDoc site sidebar still contains a stale anchor label generated previously; will be regenerated on next `yarn docs:build`.

$now

- Added docs scripts:
  * package.json: `docs:clean`, `docs:build` (TypeDoc via typedoc.json), `docs:watch`, `docs:serve` (tiny Node static server; env `DOCS_PORT`, default 8080).
  * typedoc.json: targets src/index.ts, src/CameraProps.ts, src/types.ts; excludes specs and tests; outputs to docs/site.
  * scripts/docs-serve.mjs: lightweight server for docs/site.
- Verified local presence of typedoc in node_modules; did not run the build.

$now

- Fixed TypeDoc rendering of `CameraProps`:
  * Cause: `CameraProps extends ViewProps` made TypeDoc flatten RN View props (accessibility/ARIA/etc.).
  * Fix: added `typedoc-plugin-no-inherit` and `@noInheritDoc` on `CameraProps` to hide inherited members from docs.
  * typedoc.json: set `excludeExternals`, `externalPattern`, and `visibilityFilters.inherited=false`.
  * Rebuilt: `docs/site/interfaces/CameraProps.CameraProps.html` now lists only our props.

$now

- Sidebar fix: Left nav showed three modules (CameraProps, index, types) due to `entryPointStrategy: expand` with multiple entryPoints. Switched to `resolve` and single entryPoint `src/index.ts`, and re-exported `CameraProps` + event types from `src/index.ts` to keep them in one module. Rebuilt docs; sidebar no longer splits into 3 modules.

$now

- Restored missing documentation assets and scripts:
  * docs/tsdoc-style.md (authoring guide)
  * docs/typedoc-custom.css (theme)
  * scripts/serve-docs.mjs (static server) — alias of prior docs-serve
  * scripts/postprocess-typedoc.mjs (header/footer + heading tweaks)
- Updated typedoc.json: single entry, custom CSS, hide generator, highlight languages, readme, no-external, no-inherited, excludeInternal.
- Improved TSDoc across code (Camera, Camera.android, CameraProps, types, index) with remarks/examples/categories.
- Rebuilt docs: sidebar unified, Camera page rich content, CameraProps clean, static header/footer.
- Not restoring docset builder by design (project uses TSDoc/TypeDoc only).

$now

- Expanded TSDoc across src/*:
  * CameraProps: per-prop docs (behavior, platform notes, examples), event payload types documented.
  * Camera (root): examples + category; Android/iOS components documented with remarks.
  * types.ts: enums/types documented with summaries and remarks.
  * index.ts: Orientation documented; default export marked @internal.
- Rebuilt TypeDoc; verified CameraProps page and Camera page show rich content.

$now

- Completed TSDoc sweep for all requested API symbols:
  * Camera, CameraProps, CameraApi, CaptureData, CameraType, TorchMode, FlashMode, FocusMode, ZoomMode, ResizeMode, CodeFormat, Orientation; event payloads (OnReadCodeData, OnOrientationChangeData, OnZoom).
  * Added rich remarks/examples and platform notes; clarified relationships (torch vs flash; zoomMode vs zoom).
  * Exposed and documented `CameraKit` (typed TurboModule) and kept default export as alias.
- Rebuilt docs; spot-checked pages for content depth and theme.

$now

- Restored lost CSS rules from previous custom stylesheet:
  * Added `#tsd-toolbar-links .tsd-widget` spacing/color and hover underline to `docs/theme/tesla.css`.
  * Kept header/footer custom HTML via TypeDoc (`customJs` and `customFooterHtml`).
- Rebuilt docs; verified `assets/custom.css` is emitted and header/footer render with theme.

$now

- Header toolbar CSS fixed: added flex layout + vertical centering for `#tsd-toolbar-links` and `.tsd-toolbar-contents`; ensured icon buttons align; verified in emitted assets/custom.css.

$now

- Removed JS injection from TypeDoc (customJs deleted); header links are now inserted statically during postprocess.
- Updated typedoc.json accordingly and deleted docs/theme/tesla.js.
- Rebuilt docs and confirmed header links appear without JS.
2025-09-23 11:03 UTC

## Staged Changes Review (gm/documentation-2)

- Staged: 18 files, +520/-945. Removed Dash docset workflow (`.github/workflows/docset.yml`) and docset builder script (`scripts/build-docset.mjs`); added TypeDoc theme CSS (`docs/theme/tesla.css`); updated `package.json` docs scripts; revised `typedoc.json`; updated `scripts/postprocess-typedoc.mjs` and `scripts/serve-docs.mjs`; TS sources touched: `src/Camera*.tsx`, `src/types.ts`, `src/index.ts`; `yarn.lock` updated.
- Unstaged: example project changes (`example/android/*`, `example/ios/Podfile`, `example/src/App.tsx`) and new docs/demo content (`docs/PROPOSAL-*`, `docs/REACT_NATIVE_NEW_ARCH.md`, `new-arch-minimal/`), plus this `NOTES.md`.
- Notable API nits: `Orientation` lost `as const` in `src/index.ts`; consider restoring to keep literal type union (0 | 1 | 2 | 3) for `OnOrientationChangeData` readability.
- Risk: Removing `.gitignore` entries for `docs/*.docset*` may allow accidental commits of local Dash docsets; suggest keeping ignore for safety even if we dropped docset tooling.
 - Follow-ups: run `yarn docs:build` end-to-end; smoke-test TS build; validate `docs:serve` loads toolbar links and footer; ensure `codegen:demo` succeeds if keeping `new-arch-minimal/` in repo; decide whether to stage example changes and new docs.
2025-09-23 11:08 UTC

- Fixed: restored `as const` on `Orientation` in `src/index.ts` to preserve literal value union (0 | 1 | 2 | 3) used by `OnOrientationChangeData`.
2025-09-23 11:10 UTC

- Amended latest commit message to replace literal "\n" with real newlines (was 36a9a57 → now 421b219). Updated branch pointers so both `gm/documentation-2` and `gm/documentation-3` reference the amended commit.
- Verified previous commit bodies; no other messages contain "\n" escapes.
