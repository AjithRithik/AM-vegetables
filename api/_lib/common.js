// Shared helpers for the staff admin API (api/admin/*).
// Vercel env vars: ADMIN_PASSWORD, GITHUB_TOKEN (fine-grained, Contents: read & write
// on this repo only). Optional: SESSION_SECRET, GITHUB_REPO, GITHUB_BRANCH.
const crypto = require('crypto');

const REPO = process.env.GITHUB_REPO || 'AjithRithik/AM-vegetables';
const BRANCH = process.env.GITHUB_BRANCH || 'main';
const DIR = 'content/products';
const SESSION_MS = 12 * 60 * 60 * 1000;

// ------------------------------------------------------------------ auth
const sha = (s) => crypto.createHash('sha256').update(String(s)).digest();
const safeEqual = (a, b) => crypto.timingSafeEqual(sha(a), sha(b));
const secret = () => process.env.SESSION_SECRET || process.env.ADMIN_PASSWORD || '';
const sign = (p) => crypto.createHmac('sha256', secret()).update(p).digest('base64url');

function configured(res) {
  if (!process.env.ADMIN_PASSWORD || !process.env.GITHUB_TOKEN) {
    res.status(500).json({ error: 'Server is not set up yet (ADMIN_PASSWORD / GITHUB_TOKEN missing).' });
    return false;
  }
  return true;
}

function makeToken() {
  const exp = String(Date.now() + SESSION_MS);
  return exp + '.' + sign(exp);
}

function requireAuth(req, res) {
  if (!configured(res)) return false;
  const t = (req.headers.authorization || '').replace(/^Bearer /, '');
  const [exp, mac] = t.split('.');
  if (!exp || !mac || !safeEqual(mac, sign(exp)) || Number(exp) < Date.now()) {
    res.status(401).json({ error: 'Please log in again.' });
    return false;
  }
  return true;
}

// ------------------------------------------------------------------ GitHub
async function gh(path, opts = {}) {
  const r = await fetch('https://api.github.com/repos/' + REPO + path, {
    ...opts,
    headers: {
      Authorization: 'Bearer ' + process.env.GITHUB_TOKEN,
      Accept: 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'User-Agent': 'am-veg-staff-admin',
    },
  });
  if (!r.ok) {
    const e = new Error('GitHub ' + r.status);
    e.status = r.status;
    e.body = (await r.text()).slice(0, 300);
    throw e;
  }
  return r.json();
}

// All product files in one request.
async function loadProducts() {
  const [owner, name] = REPO.split('/');
  const r = await fetch('https://api.github.com/graphql', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + process.env.GITHUB_TOKEN, 'Content-Type': 'application/json', 'User-Agent': 'am-veg-staff-admin' },
    body: JSON.stringify({
      query: `query($o:String!,$n:String!,$e:String!){repository(owner:$o,name:$n){object(expression:$e){... on Tree{entries{name object{... on Blob{text}}}}}}}`,
      variables: { o: owner, n: name, e: BRANCH + ':' + DIR },
    }),
  });
  const j = await r.json();
  const entries = j?.data?.repository?.object?.entries;
  if (!entries) throw new Error('Could not read products: ' + JSON.stringify(j.errors || j).slice(0, 200));
  return entries
    .filter((e) => e.name.endsWith('.json') && e.object && e.object.text)
    .map((e) => JSON.parse(e.object.text))
    .sort((a, b) => a.category_en.localeCompare(b.category_en) || a.name_en.localeCompare(b.name_en));
}

// One commit with many files. files: [{path, text} | {path, base64}]
async function commitFiles(files, message) {
  for (let attempt = 0; attempt < 3; attempt++) {
    const ref = await gh('/git/ref/heads/' + BRANCH);
    const head = await gh('/git/commits/' + ref.object.sha);
    const tree = [];
    for (const f of files) {
      if (f.base64) {
        const b = await gh('/git/blobs', { method: 'POST', body: JSON.stringify({ content: f.base64, encoding: 'base64' }) });
        tree.push({ path: f.path, mode: '100644', type: 'blob', sha: b.sha });
      } else {
        tree.push({ path: f.path, mode: '100644', type: 'blob', content: f.text });
      }
    }
    const t = await gh('/git/trees', { method: 'POST', body: JSON.stringify({ base_tree: head.tree.sha, tree }) });
    const c = await gh('/git/commits', { method: 'POST', body: JSON.stringify({ message, tree: t.sha, parents: [ref.object.sha] }) });
    try {
      await gh('/git/refs/heads/' + BRANCH, { method: 'PATCH', body: JSON.stringify({ sha: c.sha }) });
      return c.sha;
    } catch (e) {
      if (e.status !== 422 || attempt === 2) throw e; // someone else committed in between: retry
    }
  }
}

async function readProduct(id) {
  const f = await gh('/contents/' + DIR + '/' + encodeURIComponent(id) + '.json?ref=' + BRANCH);
  return JSON.parse(Buffer.from(f.content, 'base64').toString('utf8'));
}

// ------------------------------------------------------------------ validation
const text = (v, max) => String(v ?? '').trim().slice(0, max);

const UNITS = { weight: ['kg', 'g'], bunch: ['bunch'], piece: ['piece'] };

function packLabels(soldBy, q) {
  if (soldBy === 'weight') {
    if (q < 1) { const g = Math.round(q * 1000); return [`${g} g`, `${g} கிராம்`]; }
    return [`${q} kg`, `${q} கிலோ`];
  }
  if (soldBy === 'bunch') return [`${q} ${q === 1 ? 'Bunch' : 'Bunches'}`, `${q} கட்டு`];
  return [`${q} ${q === 1 ? 'Piece' : 'Pieces'}`, `${q} எண்ணம்`];
}

// Staff send only {quantity, is_default}; labels are generated, extras kept from the old pack.
function cleanPacks(input, soldBy, oldPacks = []) {
  if (!Array.isArray(input) || input.length < 1 || input.length > 10) throw new Error('Add 1 to 10 sizes.');
  const seen = new Set();
  const packs = input.map((p) => {
    const q = Number(p.quantity);
    if (!(q > 0) || q > 100) throw new Error('Each size needs a quantity above 0.');
    if (seen.has(q)) throw new Error('Two sizes are the same.');
    seen.add(q);
    const old = oldPacks.find((o) => Number(o.quantity) === q) || {};
    const [en, ta] = packLabels(soldBy, q);
    const out = { label_en: old.label_en || en, label_ta: old.label_ta || ta };
    if (old.note) out.note = old.note;
    out.quantity = q;
    out.unit = soldBy === 'weight' ? 'kg' : soldBy;
    out.is_default = !!p.is_default;
    if (old.popular) out.popular = true;
    return out;
  });
  const first = packs.findIndex((p) => p.is_default);
  packs.forEach((p, i) => { p.is_default = i === (first === -1 ? 0 : first); });
  return packs;
}

function imageFile(dataUrl, id) {
  const m = /^data:image\/jpeg;base64,([A-Za-z0-9+/=]+)$/.exec(String(dataUrl || ''));
  if (!m) throw new Error('Photo must be a JPEG.');
  const buf = Buffer.from(m[1], 'base64');
  if (buf.length > 1.5 * 1024 * 1024) throw new Error('Photo is too big.');
  if (!(buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff)) throw new Error('Photo is not a valid JPEG.');
  const stamp = new Date().toISOString().replace(/\D/g, '').slice(0, 12);
  const name = `${id}-${stamp}.jpg`;
  return { file: { path: 'images/uploads/products/' + name, base64: m[1] }, url: '/images/uploads/products/' + name };
}

const ID_RE = /^[a-z0-9-]{1,60}$/;
const json = (o) => JSON.stringify(o, null, 2) + '\n';

module.exports = {
  DIR, BRANCH, safeEqual, makeToken, requireAuth, configured, gh, loadProducts, commitFiles, readProduct,
  text, cleanPacks, imageFile, ID_RE, json, UNITS,
};
