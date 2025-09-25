# Our New Documentation System: A Guide for Developers

## Contents

- [1. Overview & Philosophy](#1-overview--philosophy)
- [2. How to Write Documentation (The TSDoc Standard)](#2-how-to-write-documentation-the-tsdoc-standard)
- [3. Automatic Quality Checks (Your New Superpowers)](#3-automatic-quality-checks-your-new-superpowers)
- [4. Generating and Previewing the Docs Site](#4-generating-and-previewing-the-docs-site)
- [5. Automated Deployment](#5-automated-deployment)
- [6. Scope: What Gets Documented (and What Doesn’t)](#6-scope-what-gets-documented-and-what-doesnt)
- [7. Authoring Checklist (Copy/Paste Friendly)](#7-authoring-checklist-copy-paste-friendly)
- [8. Troubleshooting](#8-troubleshooting)
- [9. Quick Commands](#9-quick-commands)
- [10. Tooling Alignment (ESLint + TypeScript)](#10-tooling-alignment-eslint--typescript)
- [11. README Assets on npm](#11-readme-assets-on-npm)

## 1. Overview & Philosophy

Welcome to the new documentation system for `react-native-camera-kit`! This guide explains how it works and how you can contribute.

Our philosophy is simple: **documentation is not optional**. To ensure our library is easy to use and maintain, we have implemented a robust, automated system to help us write and maintain high-quality, consistent, and always up-to-date documentation.

The system is built on three core technologies:
*   **[TSDoc](https://tsdoc.org/):** The standard for writing documentation comments in TypeScript.
*   **[TypeDoc](https://typedoc.org/):** The tool that generates our beautiful documentation site from our TSDoc comments.
*   **[ESLint](https://eslint.org/):** Our linter, which we've configured to provide real-time feedback on your documentation as you write it.

---

## 2. How to Write Documentation (The TSDoc Standard)

All exported components, types, functions, and constants **must** have a TSDoc comment block. A TSDoc block starts with `/**` and ends with `*/`.

### A Good Example

Here is an example of a well-documented prop within a component's props interface.

```typescript
/**
 * Props for the `Camera` component.
 */
export interface CameraProps extends ViewProps {
  /**
   * Controls the zoom factor of the camera. Higher values zoom in.
   *
   * @remarks
   * This prop is "uncontrolled" when `undefined`. In this mode, users can
   * pinch-to-zoom. When a `number` is provided, the zoom is "controlled"
   * and pinch gestures are disabled.
   *
   * @example
   * ```tsx
   * // Uncontrolled zoom (pinch-to-zoom enabled)
   * <Camera zoomMode="on" />
   *
   * // Controlled zoom (pinch-to-zoom disabled)
   * <Camera zoom={2.5} />
   * ```
   *
   * @defaultValue 1.0
   */
  zoom?: number;
}
```

### Our Custom Tag: `@category`

To keep the documentation organized, we use a custom `@category` tag. Please categorize your contributions into one of the following:

*   `Components`
*   `Constants`
*   `Enums`
*   `Events`
*   `Types`
*   `Other`

> For more detailed style guidance, please refer to the **[TSDoc Style Guide](tsdoc-style.md)**.

---

## 3. Automatic Quality Checks (Your New Superpowers)

To make writing good documentation easier, we've built in two levels of automated checks.

### Real-time Syntax Checking

As you write code in a supported editor (like VS Code with the ESLint extension), you will get **immediate feedback** on your TSDoc comments. The linter will add a red squiggle under any comment that has a syntax error.

This is powered by `eslint-plugin-tsdoc` and is designed to help you fix simple mistakes instantly.

### The Comprehensive Quality Gate: `yarn lint`

We now have a single, unified command to check the quality of the entire project:

```bash
yarn lint
```

This powerful command runs two checks in sequence:
1.  **ESLint:** It first checks the entire project for code style and TSDoc syntax errors.
2.  **TypeDoc:** If ESLint passes, it then runs TypeDoc in validation‑only mode (no HTML output).

Most importantly, the TypeDoc check is configured to be very strict. The `yarn lint` command will **fail** if any exported API that is reachable from the entry point (`src/index.ts`) is missing documentation. The enforcement covers: `Class`, `Interface`, `Function`, `Method`, `TypeAlias`, `Enum`, `EnumMember`, `Variable`, and `Property` (see `typedoc.json.requiredToBeDocumented`). This is our safety net to ensure we never have undocumented APIs.

Note: During lint, TypeDoc runs with `--emit none` to validate only, so it does not generate `docs/site`.

---

## 4. Generating and Previewing the Docs Site

You can preview the full documentation website on your local machine at any time.

1.  **Build the site:**
    ```bash
    yarn docs:build
    ```
2.  **Serve the site:**
    ```bash
    yarn docs:serve
    ```

This will start a local server, usually at **[http://localhost:8080](http://localhost:8080)**, where you can see the final result of your documentation.

Other useful scripts include:
*   `yarn docs:clean`: Deletes the generated `docs/site` directory.
*   `yarn docs:watch`: Rebuilds the documentation automatically whenever you save a file.

---

## 5. Automated Deployment

The documentation site is automatically built and deployed to GitHub Pages.

*   **On Push to `master`:** Changes merged to `master` rebuild and publish the production site.
*   **On Pull Requests (PR Preview):** CI publishes an ephemeral preview URL via GitHub Pages for PRs whose branch lives in this repository. The link appears on the PR checks as the environment URL for the "Deploy (PR Preview)" job and is cleaned up automatically when the PR closes. For forked PRs and Dependabot PRs (read‑only token) or when environment rules block previews, the build still uploads the standard `github-pages` artifact. Reviewers can download that artifact from the Actions run if a preview URL isn’t available.
*   **Manual Run on `master`:** From Actions → "Docs (TypeDoc → GitHub Pages)" → "Run workflow", choose `Branch: master` to trigger a production deploy on demand.

Lint vs. deploy: `yarn lint` validates documentation coverage (no HTML). The Docs workflow builds the HTML site and deploys it.

### Repository setting required for PR previews

- Go to Settings → Environments → `github-pages` and set Deployment branches to "All branches" (or include your PR branch patterns). If restricted to only `master`, preview deploys from feature branches will be blocked by environment rules.

---

## 6. Scope: What Gets Documented (and What Doesn’t)

- Public API surface is everything exported (directly or indirectly) from `src/index.ts`. That is the single entry point used by TypeDoc.
- Internal React Native codegen specs under `src/specs/**` are excluded from the public site. Document the user‑facing API where it’s exposed (e.g., `src/Camera.tsx`, `src/CameraProps.ts`, `src/types.ts`, and re‑exports in `src/index.ts`).
- The TypeDoc configuration (`typedoc.json`) enforces that exported symbols of kinds `Class`, `Interface`, `Function`, `Method`, `TypeAlias`, `Enum`, `EnumMember`, `Variable`, and `Property` must be documented.

> ESLint and custom tags: We ship a `tsdoc.json` file that defines custom tags like `@category` and `@noInheritDoc` so ESLint’s TSDoc parser recognizes them. TypeDoc ignores unknown tags gracefully, but ESLint needs this file to validate comment syntax correctly.

---

## 7. Authoring Checklist (Copy/Paste Friendly)

- Every exported symbol has a TSDoc block with a one‑line summary.
- Use `@category` exactly once, choosing from: `Components`, `Constants`, `Enums`, `Events`, `Types`, `Other`.
- Add `@remarks` for platform notes and caveats (e.g., “Platform: iOS/Android”).
- Include `@defaultValue` for defaults (especially sentinel values like `-1`).
- Provide a small `@example` where usage might be non‑obvious.
- For events, document `nativeEvent` and its fields explicitly.
- Use `@noInheritDoc` for props interfaces when inherited `ViewProps` noise would hurt readability.
- Re‑export from `src/index.ts` so the symbol is reachable by the docs entry point.

---

## 8. Troubleshooting

- ESLint TSDoc: `tsdoc-undefined-tag`
  - Ensure the tag is declared in `tsdoc.json` (e.g., `@category`, `@noInheritDoc`) and spelled correctly.
- TypeDoc: “not documented” (warnings treated as errors)
  - Confirm the symbol is exported (directly or indirectly) via `src/index.ts` and has a TSDoc block.
  - Remember that `Method`, `Property`, and `EnumMember` also require docs.
- TypeDoc: invalid links
  - Fix broken `{@link ...}` references; `typedoc.json.validation.invalidLink` is enabled.
- Specs directory issues
  - `src/specs/**` is internal and excluded from public docs; document user‑facing wrappers instead.
- “Why doesn’t lint generate HTML?”
  - Lint runs TypeDoc with `--emit none` for speed; build the site with `yarn docs:build`.
- “Why do we map a few @typescript-eslint rules to base ESLint rules?”
  - We use `@typescript-eslint` v8 to support TypeScript 5.9+. Some legacy “extension rules” were removed upstream.
    Until `@react-native/eslint-config` stops referencing them, we locally disable the removed extension rule(s) and
    enable the equivalent base ESLint rule(s) to preserve behavior.

---

## 9. Quick Commands

- Validate code style + docs coverage: `yarn lint`
- Build docs site: `yarn docs:build`
- Serve docs site: `yarn docs:serve`
- Clean generated site: `yarn docs:clean`
- Rebuild on save: `yarn docs:watch`

---

## 10. Tooling Alignment (ESLint + TypeScript)

Why we changed it
- We upgraded our lint stack to officially support TypeScript 5.9 and to remove the “unsupported TypeScript version” warning coming from `@typescript-eslint/typescript-estree`.
- We deliberately stayed on ESLint 8.x to avoid an unrelated migration to ESLint 9 “flat config” for now.

What we use now
- ESLint: 8.57.x
- TypeScript: 5.9.x
- `@typescript-eslint/parser`: ^8.44.x
- `@typescript-eslint/eslint-plugin`: ^8.44.x

Deterministic dependency alignment
- We use Yarn `resolutions` to ensure the entire tree (including transitive deps) resolves to compatible versions and does not load older copies that print warnings:
  ```json
  {
    "resolutions": {
      "@typescript-eslint/parser": "^8.44.1",
      "@typescript-eslint/eslint-plugin": "^8.44.1",
      "@typescript-eslint/utils": "^8.44.1",
      "@typescript-eslint/typescript-estree": "^8.44.1",
      "eslint-plugin-jest": "^29.0.1"
    }
  }
  ```

Explicit parser selection
- We set the parser explicitly at the root to avoid ESLint picking a nested parser from an extended config:
  ```js
  // .eslintrc.js
  module.exports = {
    parser: '@typescript-eslint/parser',
    // ...
  };
  ```

Diagnostics (useful commands)
- Which parser is ESLint actually using for a file?
  ```bash
  eslint --print-config src/index.ts | rg '"parser"\s*:\\s*".*parser'
  ```
- Show all installed versions of typescript-estree:
  ```bash
  yarn why @typescript-eslint/typescript-estree
  ```
- Inspect runtime versions quickly:
  ```bash
  node -p "({parser:require('@typescript-eslint/parser/package.json').version, estree:require('@typescript-eslint/typescript-estree/package.json').version, eslint:require('eslint/package.json').version, ts:require('typescript/package.json').version})"
  ```

Why a small shim was needed
- `@typescript-eslint` v8 removed several legacy “extension rules” (rules that duplicated core ESLint behavior for TypeScript). Some external configs (including `@react-native/eslint-config`) still reference those old rule names.
- To keep behavior identical and unblock the upgrade, we map the removed rule(s) to the equivalent core ESLint rule(s) locally in `.eslintrc.js`.

Example shim we added
```
// typescript-eslint v8 removed extension rules. Map to base rules to preserve behavior
'@typescript-eslint/func-call-spacing': 'off',
'func-call-spacing': ['error', 'never'],
```

Notes
- This shim is intentionally minimal. If future lint runs complain about other removed extension rules, add a focused mapping for the specific rule only (e.g., `@typescript-eslint/quotes` → `quotes`).
- Once `@react-native/eslint-config` no longer references removed extension rules, we can delete these mappings.
- We will consider ESLint 9 + flat config separately when the ecosystem is ready.

---

## 11. README Assets on npm

- The README header references `./images/header.png`. To ensure npm renders the image, the `images/` folder is included in the package via `package.json#files`.
- If you add new README assets in the future:
  - Either add their folder to `package.json#files`, or
  - Use absolute URLs (e.g., a GitHub raw link) so npm can resolve them.
