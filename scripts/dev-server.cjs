#!/usr/bin/env node
// Local dev server: serves the site statically AND runs the api/ functions, reading .env.local.
//   npm run dev:admin     ->  http://localhost:8080/staff
// (On Vercel the same api/ files run as serverless functions, set the env vars there.)
const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const PORT = Number(process.env.PORT) || 8080;

try {
  for (const line of fs.readFileSync(path.join(ROOT, '.env.local'), 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
} catch (_) { /* no .env.local */ }

const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
};

function readBody(req) {
  return new Promise((resolve) => {
    let b = '';
    req.on('data', (c) => { b += c; if (b.length > 1e6) req.destroy(); });
    req.on('end', () => { try { resolve(b ? JSON.parse(b) : {}); } catch (_) { resolve({}); } });
  });
}

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  let p = decodeURIComponent(url.pathname);

  if (p.startsWith('/api/')) {
    const file = path.join(ROOT, p.replace(/\/+$/, '') + '.js');
    if (!file.startsWith(path.join(ROOT, 'api')) || path.basename(file).startsWith('_') || !fs.existsSync(file)) {
      res.writeHead(404, { 'Content-Type': 'application/json' }); return res.end('{"error":"Not found"}');
    }
    req.body = await readBody(req);
    res.status = (c) => { res.statusCode = c; return res; };
    res.json = (o) => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(o)); };
    try { delete require.cache[require.resolve(file)]; await require(file)(req, res); }
    catch (e) { console.error(e); if (!res.writableEnded) res.status(500).json({ error: e.message }); }
    return;
  }

  // static files; never serve dotfiles or the server-side folders
  const parts = p.split('/').filter(Boolean);
  if (parts.some((s) => s.startsWith('.')) || ['node_modules', 'scripts', 'api', 'supabase'].includes(parts[0])) {
    res.writeHead(404); return res.end('Not found');
  }
  let file = path.join(ROOT, ...parts);
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
  else if (!fs.existsSync(file) && fs.existsSync(path.join(file, 'index.html'))) file = path.join(file, 'index.html');
  if (!file.startsWith(ROOT) || !fs.existsSync(file)) { res.writeHead(404); return res.end('Not found'); }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
  fs.createReadStream(file).pipe(res);
}).listen(PORT, () => console.log(`Admin: http://localhost:${PORT}/staff   (Ctrl+C to stop)`));
