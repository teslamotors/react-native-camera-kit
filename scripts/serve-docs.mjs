#!/usr/bin/env node
import http from 'http';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, '..');
const DOCS_DIR = path.join(ROOT, 'docs', 'site');

const PORT = Number(process.env.DOCS_PORT || 8080);

const MIME = new Map(Object.entries({
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.json': 'application/json; charset=utf-8',
}));

function contentTypeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return MIME.get(ext) || 'application/octet-stream';
}

async function ensureDocs() {
  try {
    await fs.access(DOCS_DIR);
  } catch {
    console.error('[docs:serve] docs/site not found. Run `yarn docs:build` first.');
    process.exit(1);
  }
}

function sanitizeUrl(urlPath) {
  try {
    const decoded = decodeURIComponent(urlPath.split('?')[0]);
    // Prevent path traversal
    const p = path.normalize(decoded).replace(/^\/+/, '');
    return p;
  } catch {
    return 'index.html';
  }
}

async function serve() {
  await ensureDocs();

  const server = http.createServer(async (req, res) => {
    const rel = sanitizeUrl(req.url || '/');
    let filePath = path.join(DOCS_DIR, rel);

    try {
      const st = await fs.stat(filePath).catch(() => null);
      if (!st) {
        // Fallback for SPA-style links: try appending .html
        if (!rel.endsWith('.html')) {
          const tryHtml = filePath + '.html';
          const stHtml = await fs.stat(tryHtml).catch(() => null);
          if (stHtml) filePath = tryHtml;
        }
      } else if (st.isDirectory()) {
        filePath = path.join(filePath, 'index.html');
      }

      const data = await fs.readFile(filePath);
      res.writeHead(200, { 'Content-Type': contentTypeFor(filePath) });
      res.end(data);
    } catch (e) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Not found');
    }
  });

  server.listen(PORT, () => {
    console.log(`[docs:serve] Serving ${DOCS_DIR} at http://localhost:${PORT}`);
  });
}

serve().catch((e) => {
  console.error('[docs:serve] Error:', e);
  process.exit(1);
});

