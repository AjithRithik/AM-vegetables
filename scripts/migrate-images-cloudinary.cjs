// One-time: upload product photos to Cloudinary and point each product at the new URL.
//   node scripts/migrate-images-cloudinary.cjs --dry-run   (shows what it would do)
//   node scripts/migrate-images-cloudinary.cjs             (does it)
// Reads CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET from .env.
// Safe to re-run: products whose image is already an http(s) URL are skipped.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const root = path.resolve(__dirname, '..');
const dry = process.argv.includes('--dry-run');
const only = (process.argv.find((a) => a.startsWith('--only=')) || '').slice(7); // e.g. --only=spring-onion

// --- minimal .env reader (tolerates spaces around "=" and quotes)
const env = {};
const envFile = path.join(root, '.env');
if (fs.existsSync(envFile)) {
  for (const line of fs.readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/.exec(line);
    if (m) env[m[1]] = m[2].replace(/^(['"])(.*)\1$/, '$2');
  }
}
const cloud = process.env.CLOUDINARY_CLOUD_NAME || env.CLOUDINARY_CLOUD_NAME;
const apiKey = process.env.CLOUDINARY_API_KEY || env.CLOUDINARY_API_KEY;
const apiSecret = process.env.CLOUDINARY_API_SECRET || env.CLOUDINARY_API_SECRET;
const missing = [['CLOUDINARY_CLOUD_NAME', cloud], ['CLOUDINARY_API_KEY', apiKey], ['CLOUDINARY_API_SECRET', apiSecret]]
  .filter(([, v]) => !v).map(([k]) => k);
if (missing.length) {
  console.error('Missing in .env: ' + missing.join(', '));
  process.exit(1);
}

const dir = path.join(root, 'content/products');
const FOLDER = 'am-veg/products';

async function upload(file, id) {
  const params = {
    folder: FOLDER,
    public_id: id,
    overwrite: 'true',
    // Stored copy is capped at 1200 px and re-compressed, so storage stays tiny.
    transformation: 'c_limit,w_1200,q_auto:good',
    timestamp: Math.floor(Date.now() / 1000),
  };
  const toSign = Object.keys(params).sort().map((k) => `${k}=${params[k]}`).join('&');
  const signature = crypto.createHash('sha1').update(toSign + apiSecret).digest('hex');
  const body = new FormData();
  for (const [k, v] of Object.entries(params)) body.append(k, String(v));
  body.append('api_key', apiKey);
  body.append('signature', signature);
  body.append('file', new Blob([fs.readFileSync(file)]), path.basename(file));
  const r = await fetch(`https://api.cloudinary.com/v1_1/${cloud}/image/upload`, { method: 'POST', body });
  const j = await r.json();
  if (!r.ok) throw new Error(`${id}: ${j.error?.message || r.status}`);
  return j.secure_url;
}

(async () => {
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json'));
  let done = 0, skipped = 0, failed = 0, bytes = 0;
  for (const f of files) {
    const p = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
    if (only && p.id !== only) continue;
    if (!p.image || /^https?:/.test(p.image)) { skipped++; continue; }
    const local = path.join(root, p.image.replace(/^\//, ''));
    if (!fs.existsSync(local)) { console.warn(`- ${p.id}: file not found (${p.image})`); failed++; continue; }
    bytes += fs.statSync(local).size;
    if (dry) { console.log(`would upload ${p.image}`); done++; continue; }
    try {
      p.image = await upload(local, p.id);
      fs.writeFileSync(path.join(dir, f), JSON.stringify(p, null, 2) + '\n');
      console.log(`✓ ${p.id}`);
      done++;
    } catch (e) { console.warn(`✗ ${p.id}: ${e.message}${e.cause ? ' (' + (e.cause.code || e.cause.message) + ')' : ''}`); failed++; }
  }
  console.log(`\n${dry ? 'Would upload' : 'Uploaded'} ${done}, skipped ${skipped}, failed ${failed} (${(bytes / 1048576).toFixed(0)} MB of originals)`);
  if (!dry && done) { require('./build-products.cjs'); }
})();
