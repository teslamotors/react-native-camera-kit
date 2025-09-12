#!/usr/bin/env node
import { promises as fs } from 'fs';
import path from 'path';
import { execFile, spawn } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT = path.join(__dirname, '..');
const DOCS_HTML_DIR = path.join(ROOT, 'docs', 'site');
const DOCSET_DIR = path.join(ROOT, 'docs', 'react-native-camera-kit.docset');
const CONTENTS_DIR = path.join(DOCSET_DIR, 'Contents');
const RESOURCES_DIR = path.join(CONTENTS_DIR, 'Resources');
const DOCUMENTS_DIR = path.join(RESOURCES_DIR, 'Documents');
const DSIDX_PATH = path.join(RESOURCES_DIR, 'docSet.dsidx');

function sh(cmd, args, opts = {}) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { ...opts }, (err, stdout, stderr) => {
      if (err) return reject(Object.assign(err, { stdout, stderr }));
      resolve({ stdout, stderr });
    });
  });
}

async function ensureDocsBuilt() {
  try {
    await fs.access(DOCS_HTML_DIR);
  } catch {
    console.log('[docset] docs/site not found; building with TypeDoc…');
    await sh('yarn', ['docs:build'], { cwd: ROOT });
  }
}

async function rimraf(p) {
  await fs.rm(p, { recursive: true, force: true });
}

async function mkdirp(p) {
  await fs.mkdir(p, { recursive: true });
}

async function copyDir(src, dest) {
  await mkdirp(dest);
  const entries = await fs.readdir(src, { withFileTypes: true });
  for (const e of entries) {
    const s = path.join(src, e.name);
    const d = path.join(dest, e.name);
    if (e.isDirectory()) await copyDir(s, d);
    else if (e.isSymbolicLink()) {
      const target = await fs.readlink(s);
      await fs.symlink(target, d);
    } else {
      await fs.copyFile(s, d);
    }
  }
}

function plist(obj) {
  // Minimal Info.plist writer for Dash docsets
  const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  const entries = Object.entries(obj)
    .map(([k, v]) => {
      let xmlVal;
      if (typeof v === 'boolean') xmlVal = `<${v ? 'true' : 'false'}/>`;
      else if (typeof v === 'number') xmlVal = `<integer>${v}</integer>`;
      else xmlVal = `<string>${esc(v)}</string>`;
      return `    <key>${esc(k)}</key>\n    ${xmlVal}`;
    })
    .join('\n');
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
${entries}
  </dict>
</plist>\n`;
}

function mapTypeForPath(relPath, name) {
  // Map TypeDoc output folders to Dash entry types
  // See: https://kapeli.com/docsets#supportedentrytypes
  if (relPath.startsWith('interfaces/')) return 'Interface';
  if (relPath.startsWith('classes/')) return 'Class';
  if (relPath.startsWith('enums/')) return 'Enum';
  if (relPath.startsWith('functions/')) return 'Function';
  if (relPath.startsWith('types/')) return 'Type';
  if (relPath.startsWith('variables/')) {
    if (relPath === 'variables/Camera.html') return 'Component';
    if (name === 'Orientation') return 'Constant';
    return 'Variable';
  }
  if (relPath === 'index.html') return 'Guide';
  if (relPath === 'modules.html') return 'Module';
  return 'Guide';
}

async function* walk(dir, base = dir) {
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(full, base);
    else yield path.relative(base, full);
  }
}

async function buildIndex() {
  // Build minimal search index from generated HTML structure
  const records = [];
  for await (const rel of walk(DOCUMENTS_DIR, DOCUMENTS_DIR)) {
    if (!rel.endsWith('.html')) continue;
    // Skip assets pages
    if (rel.startsWith('assets/') || rel.startsWith('media/')) continue;
    const base = path.basename(rel, '.html');
    // Ignore unnamed default page under variables
    if (rel.startsWith('variables/') && base === 'default') continue;
    const type = mapTypeForPath(rel, base);
    const name = base;
    records.push({ name, type, path: rel });
  }
  return records;
}

async function writeSQLiteIndex(records) {
  // Ensure sqlite3 CLI exists
  try {
    await sh('sqlite3', ['-version']);
  } catch (e) {
    throw new Error('sqlite3 CLI not found. Install sqlite3 or adjust the builder to use a JS SQLite lib.');
  }

  await rimraf(DSIDX_PATH);
  const stmts = [
    'PRAGMA encoding="UTF-8";',
    'PRAGMA journal_mode=DELETE;',
    'PRAGMA synchronous=OFF;',
    'PRAGMA busy_timeout=2000;',
    'CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);',
    'CREATE UNIQUE INDEX anchor ON searchIndex(name, type, path);',
  ];
  for (const r of records) {
    const esc = (s) => String(s).replace(/'/g, "''");
    stmts.push(`INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES ('${esc(r.name)}','${esc(r.type)}','${esc(r.path)}');`);
  }
  // Feed all statements in one go via stdin to avoid interactive hangs
  await new Promise((resolve, reject) => {
    const child = spawn('sqlite3', [DSIDX_PATH], { stdio: ['pipe', 'pipe', 'pipe'] });
    let stderr = '';
    child.stderr.on('data', (d) => (stderr += d.toString()));
    child.on('error', reject);
    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`sqlite3 exited with code ${code}: ${stderr}`));
      } else {
        resolve();
      }
    });
    child.stdin.write(stmts.join('\n'));
    child.stdin.end();
  });
}

async function main() {
  await ensureDocsBuilt();
  await rimraf(DOCSET_DIR);
  await mkdirp(DOCUMENTS_DIR);
  await copyDir(DOCS_HTML_DIR, DOCUMENTS_DIR);

  const info = plist({
    CFBundleIdentifier: 'com.teslamotors.react-native-camera-kit',
    CFBundleName: 'React Native Camera Kit',
    DocSetPlatformFamily: 'react-native',
    isDashDocset: true,
    dashIndexFilePath: 'index.html',
    DashDocSetDefaultFTSEnabled: true,
    DashDocSetFallbackURL: 'https://github.com/teslamotors/react-native-camera-kit',
  });
  await fs.writeFile(path.join(CONTENTS_DIR, 'Info.plist'), info, 'utf8');

  const records = await buildIndex();
  await writeSQLiteIndex(records);

  console.log(`[docset] Built ${DOCSET_DIR}`);
  console.log(`[docset] Indexed ${records.length} entries`);
}

main().catch((err) => {
  console.error('[docset] Error:', err.message);
  process.exit(1);
});
