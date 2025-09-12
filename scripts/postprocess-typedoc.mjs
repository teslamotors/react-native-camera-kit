#!/usr/bin/env node
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, '..');
const CAMERA_PAGE = path.join(ROOT, 'docs', 'site', 'variables', 'Camera.html');

async function rewriteCameraHeading() {
  try {
    let html = await fs.readFile(CAMERA_PAGE, 'utf8');
    // Replace the H1 heading label from "Variable Camera [Const]" to "Component Camera"
    html = html.replace(/<h1>\s*Variable Camera(?:<code[^>]*>[^<]*<\/code>)?\s*<\/h1>/, '<h1>Component Camera<\/h1>');
    await fs.writeFile(CAMERA_PAGE, html, 'utf8');
    console.log('[postprocess] Rewrote Camera heading to "Component Camera"');
  } catch (e) {
    console.warn('[postprocess] Camera page not found or rewrite failed:', e.message);
  }
}

async function hardenInlineThemeScript() {
  // Guard localStorage access so environments without it (e.g., some WebViews) don't break navigation
  const DOCS_DIR = path.join(ROOT, 'docs', 'site');
  /** @type {string[]} */
  const stack = [DOCS_DIR];
  const files = [];
  while (stack.length) {
    const dir = stack.pop();
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) stack.push(full);
      else if (e.isFile() && e.name.endsWith('.html')) files.push(full);
    }
  }
  let patched = 0;
  for (const f of files) {
    let html = await fs.readFile(f, 'utf8');
    const before = html;
    html = html.replace(
      /document\.documentElement\.dataset\.theme\s*=\s*localStorage\.getItem\(("|')tsd-theme\1\)\s*\|\|\s*("|')os\2\s*;/,
      'try{document.documentElement.dataset.theme = localStorage.getItem("tsd-theme") || "os";}catch(_){document.documentElement.dataset.theme = "os";}'
    );
    if (html !== before) {
      await fs.writeFile(f, html, 'utf8');
      patched++;
    }
  }
  console.log(`[postprocess] Hardened inline theme script in ${patched} file(s)`);
}

async function convertAsyncScriptsToDefer() {
  const DOCS_DIR = path.join(ROOT, 'docs', 'site');
  const files = [];
  const stack = [DOCS_DIR];
  while (stack.length) {
    const dir = stack.pop();
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) stack.push(full);
      else if (e.isFile() && e.name.endsWith('.html')) files.push(full);
    }
  }
  let patched = 0;
  for (const f of files) {
    let html = await fs.readFile(f, 'utf8');
    const before = html;
    // Replace async with defer for TypeDoc asset scripts to preserve order
    html = html.replace(/<script\s+async\s+src=\"assets\/(icons|search|navigation)\.js\"/g, '<script defer src="assets/$1.js"');
    if (html !== before) {
      await fs.writeFile(f, html, 'utf8');
      patched++;
    }
  }
  console.log(`[postprocess] Converted async->defer on ${patched} file(s)`);
}

async function reorderAssetScripts() {
  const DOCS_DIR = path.join(ROOT, 'docs', 'site');
  const files = [];
  const stack = [DOCS_DIR];
  while (stack.length) {
    const dir = stack.pop();
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const e of entries) {
      const full = path.join(dir, e.name);
      if (e.isDirectory()) stack.push(full);
      else if (e.isFile() && e.name.endsWith('.html')) files.push(full);
    }
  }
  let patched = 0;
  for (const f of files) {
    let html = await fs.readFile(f, 'utf8');
    const before = html;
    // Ensure navigation.js loads before main.js: move main.js defer tag after icons/search/navigation
    html = html.replace(
      /(\<link[^>]+custom\.css\"[^>]*\>\s*)(<script[^>]+src=\"assets\/main\.js\"[^>]*><\/script>)([\s\S]*?)(<script[^>]+src=\"assets\/navigation\.js\"[^>]*><\/script>)/,
      (m, pre, mainTag, middle, navTag) => `${pre}${middle}${navTag}\n${mainTag}`
    );
    if (html !== before) {
      await fs.writeFile(f, html, 'utf8');
      patched++;
    }
  }
  console.log(`[postprocess] Reordered scripts in ${patched} file(s)`);
}

await rewriteCameraHeading();
await hardenInlineThemeScript();
await convertAsyncScriptsToDefer();
await reorderAssetScripts();
