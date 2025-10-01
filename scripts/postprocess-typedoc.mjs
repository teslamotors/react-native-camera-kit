#!/usr/bin/env node
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { join, extname } from 'node:path';

const root = join(process.cwd(), 'docs/site');

function patchAllHtml(dir = root) {
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const d of entries) {
    const p = join(dir, d.name);
    if (d.isDirectory()) {
      patchAllHtml(p);
    } else if (d.isFile() && extname(p) === '.html') {
      let html = readFileSync(p, 'utf8');
      // Keep generator; restructure footer into a single container
      // Case 1: <footer><p class="tsd-generator">...</p><div class="container">Made by ...</div></footer>
      html = html.replace(
        /<footer>\s*<p class=\"tsd-generator\">([\s\S]*?)<\/p>\s*<div class=\"container\">([\s\S]*?)<\/div>\s*<\/footer>/g,
        '<footer><div class="container"><p class="tsd-generator">$1</p><p>$2</p></div></footer>'
      );
      // Case 2: <footer><div class="container">..</div><p class="tsd-generator">..</p></footer>
      html = html.replace(
        /<footer>\s*<div class=\"container\">([\s\S]*?)<\/div>\s*<p class=\"tsd-generator\">([\s\S]*?)<\/p>\s*<\/footer>/g,
        '<footer><div class="container"><p class="tsd-generator">$2</p><p>$1</p></div></footer>'
      );
      // Insert static header links into empty toolbar container (no JS runtime)
      html = html.replace(
        /<div id=\"tsd-toolbar-links\"><\/div>/,
        '<div id="tsd-toolbar-links"><a href="https://github.com/teslamotors/react-native-camera-kit" class="tsd-widget" target="_blank" rel="noreferrer noopener">GitHub</a><a href="https://www.tesla.com" class="tsd-widget" target="_blank" rel="noreferrer noopener">Tesla</a></div>'
      );

      // Expand sidebar categories/groups by default by opening any <details> in the nav after it renders
      const expandScript = `\n<script>(function(){\n  function expandNav(){\n    try{\n      var nav = document.getElementById('tsd-nav-container');\n      if(!nav) return;\n      nav.querySelectorAll('details').forEach(function(d){ d.open = true; });\n      nav.querySelectorAll('[aria-expanded=\\"false\\"]').forEach(function(el){ el.setAttribute('aria-expanded','true'); });\n    }catch(e){}\n  }\n  if (document.readyState === 'loading'){\n    document.addEventListener('DOMContentLoaded', function(){ setTimeout(expandNav, 0); });\n  } else {\n    setTimeout(expandNav, 0);\n  }\n})();<\/script>`;
      html = html.replace(/<\/body>/, expandScript + '\n</body>');
      writeFileSync(p, html);
    }
  }
}

function patchCameraHeading() {
  const file = join(root, 'variables', 'Camera.html');
  if (!existsSync(file)) return;
  let html = readFileSync(file, 'utf8');
  html = html.replace(/<h1>Variable Camera<code[^>]*>Const<\/code><\/h1>/, '<h1>Component Camera</h1>');
  html = html.replace(/Variable Camera/g, 'Component Camera');
  writeFileSync(file, html);
}

patchAllHtml();
patchCameraHeading();
console.log('[postprocess-typedoc] Applied header/footer and headings tweaks.');
