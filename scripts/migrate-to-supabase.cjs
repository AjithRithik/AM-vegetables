#!/usr/bin/env node
// Loads the current catalogue (content/products/*.json + content/shop.json) into Supabase.
// Idempotent: safe to re-run. Vendor edits to availability/stock are never overwritten
// (location_products rows are inserted only when missing).
//
//   node scripts/migrate-to-supabase.cjs --dry-run   # no credentials needed, prints a report
//   node scripts/migrate-to-supabase.cjs             # real run (needs .env.local)
//
// .env.local (git-ignored):
//   SUPABASE_URL=https://xxxx.supabase.co
//   SUPABASE_SERVICE_ROLE_KEY=...      # server-side only, never ship in the app
//   OWNER_PHONE=9876543210             # optional: owner logs in with this mobile number
//   OWNER_EMAIL=you@example.com
//   OWNER_PASSWORD=choose-a-strong-one # only used when the owner account does not exist yet
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const DRY = process.argv.includes('--dry-run');

const LOCATIONS = [
  { slug: 'krishnan-kovil', name_en: 'Krishnan Kovil', name_ta: 'கிருஷ்ணன் கோவில்', sort: 1 },
  { slug: 'srivilliputtur', name_en: 'Srivilliputtur', name_ta: 'ஸ்ரீவில்லிபுத்தூர்', sort: 2 },
  { slug: 'sivakasi', name_en: 'Sivakasi', name_ta: 'சிவகாசி', sort: 3 },
];

// ------------------------------------------------------------------ env
function loadEnv() {
  const f = path.join(ROOT, '.env.local');
  if (!fs.existsSync(f)) return;
  for (const line of fs.readFileSync(f, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
}

const slugify = (s) => s.toLowerCase().replace(/&/g, 'and').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const chunk = (a, n) => Array.from({ length: Math.ceil(a.length / n) }, (_, i) => a.slice(i * n, i * n + n));

// ------------------------------------------------------------------ read source files
function readSource() {
  const dir = path.join(ROOT, 'content', 'products');
  const products = fs.readdirSync(dir).filter((f) => f.endsWith('.json'))
    .map((f) => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')));
  products.sort((a, b) => (a.sort || 0) - (b.sort || 0));
  const shop = JSON.parse(fs.readFileSync(path.join(ROOT, 'content', 'shop.json'), 'utf8'));
  return { products, shop };
}

function buildPlan({ products, shop }) {
  const iconByCat = Object.fromEntries((shop.category_icons || []).map((c) => [c.category, c.icon]));
  const cats = new Map();
  for (const p of products) {
    if (!cats.has(p.category_en)) {
      cats.set(p.category_en, {
        slug: slugify(p.category_en), name_en: p.category_en, name_ta: p.category_ta || '',
        icon: iconByCat[p.category_en] || '', sort: cats.size + 1,
      });
    }
  }
  const imageUrls = [...new Set(products.map((p) => p.image).filter(Boolean))];
  const packs = [];
  products.forEach((p) => (p.packs || []).forEach((k, i) => packs.push({ product_id: p.id, sort: i, ...k })));
  return { cats: [...cats.values()], imageUrls, packs };
}

function report({ products, shop }, plan) {
  const noImage = products.filter((p) => !p.image).map((p) => p.id);
  const noPack = products.filter((p) => !(p.packs || []).length).map((p) => p.id);
  const dupIds = products.map((p) => p.id).filter((id, i, a) => a.indexOf(id) !== i);
  const badIds = products.map((p) => p.id).filter((id) => !/^[a-z0-9-]+$/.test(id));
  const badUnits = plan.packs.filter((k) => !['kg', 'piece', 'bunch'].includes(k.unit)).length;
  const badSold = products.filter((p) => !['weight', 'piece', 'bunch'].includes(p.sold_by)).map((p) => p.id);
  console.log('Source report');
  console.log('  products          :', products.length);
  console.log('  packs             :', plan.packs.length);
  console.log('  categories        :', plan.cats.length, plan.cats.map((c) => c.name_en).join(', '));
  console.log('  distinct images   :', plan.imageUrls.length);
  console.log('  locations to seed :', LOCATIONS.map((l) => l.name_en).join(', '));
  console.log('  location_products :', products.length * LOCATIONS.length, '(all enabled, as per current in_stock/featured)');
  const problems = { noImage, noPack, dupIds, badIds, badSold, badUnits };
  let bad = false;
  for (const [k, v] of Object.entries(problems)) {
    const n = Array.isArray(v) ? v.length : v;
    if (n) { bad = true; console.log('  PROBLEM', k, ':', Array.isArray(v) ? v.slice(0, 10).join(', ') : v); }
  }
  if (!bad) console.log('  checks            : OK');
  return !bad;
}

// ------------------------------------------------------------------ supabase helpers
async function must(promise, what) {
  const { data, error } = await promise;
  if (error) throw new Error(what + ': ' + error.message);
  return data;
}

async function upsert(sb, table, rows, onConflict, opts = {}) {
  let out = [];
  for (const part of chunk(rows, 200)) {
    const data = await must(sb.from(table).upsert(part, { onConflict, ...opts }).select(), 'upsert ' + table);
    out = out.concat(data || []);
  }
  return out;
}

async function ensureOwner(sb) {
  let phone = String(process.env.OWNER_PHONE || '').replace(/\D/g, '');
  if (phone.length === 10) phone = '91' + phone;
  const mapped = phone.length === 12 ? phone + '@phone.am-veg.vercel.app' : '';
  const email = mapped || process.env.OWNER_EMAIL;
  if (!email) { console.log('  owner: OWNER_PHONE / OWNER_EMAIL not set, skipped'); return; }
  let user;
  for (let page = 1; !user; page++) {
    const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw new Error('listUsers: ' + error.message);
    user = data.users.find((u) => (u.email || '').toLowerCase() === email.toLowerCase());
    if (data.users.length < 200) break;
  }
  // Switching an existing email-based owner to phone login keeps the same account.
  if (!user && mapped && process.env.OWNER_EMAIL) {
    for (let page = 1; !user; page++) {
      const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 200 });
      if (error) throw new Error('listUsers: ' + error.message);
      user = data.users.find((u) => (u.email || '').toLowerCase() === process.env.OWNER_EMAIL.toLowerCase());
      if (data.users.length < 200) break;
    }
    if (user) {
      const { error } = await sb.auth.admin.updateUserById(user.id, { email: mapped, email_confirm: true });
      if (error) throw new Error('switch owner to phone login: ' + error.message);
      console.log('  owner: login switched to mobile number', phone);
    }
  }
  if (!user) {
    if (!process.env.OWNER_PASSWORD) throw new Error('OWNER_PASSWORD is required to create the owner account.');
    const { data, error } = await sb.auth.admin.createUser({
      email, password: process.env.OWNER_PASSWORD, email_confirm: true,
    });
    if (error) throw new Error('createUser: ' + error.message);
    user = data.user;
    console.log('  owner: created', email);
  } else {
    console.log('  owner: account exists', email);
  }
  await upsert(sb, 'profiles', [{ user_id: user.id, role: 'owner', name: 'Owner', email, phone: mapped ? phone : '' }], 'user_id');
}

// ------------------------------------------------------------------ main
async function main() {
  loadEnv();
  const src = readSource();
  const plan = buildPlan(src);
  const ok = report(src, plan);
  if (!ok) { console.error('\nFix the problems above first.'); process.exit(1); }
  if (DRY) { console.log('\nDry run only, nothing was written.'); return; }

  const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.local');
  const { createClient } = require('@supabase/supabase-js');
  const sb = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });
  const { products, shop } = src;

  console.log('\nWriting to', url);

  const locs = await upsert(sb, 'locations', LOCATIONS, 'slug');
  console.log('  locations         :', locs.length);

  // Location settings: seeded once, never overwritten afterwards (vendors own them).
  await upsert(sb, 'location_settings', locs.map((l) => ({
    location_id: l.id, whatsapp: shop.whatsapp || '', phone: shop.phone || '', hours: shop.hours || '',
    is_open: shop.is_open !== false, payment_note: shop.payment_note || '', banner: shop.banner || {}, pincodes: [],
  })), 'location_id', { ignoreDuplicates: true });

  const globalSettings = {
    name_en: shop.name_en, name_ta: shop.name_ta, badge: shop.badge, logo: shop.logo,
    splash_tagline_en: shop.splash_tagline_en, splash_tagline_ta: shop.splash_tagline_ta,
    open_label_en: shop.open_label_en, open_label_ta: shop.open_label_ta,
    no_payment: shop.no_payment, how_it_works: shop.how_it_works, footer_badges: shop.footer_badges,
  };
  await upsert(sb, 'app_settings', [{ key: 'shop', value: globalSettings }], 'key');

  const cats = await upsert(sb, 'categories', plan.cats, 'slug');
  const catId = Object.fromEntries(cats.map((c) => [c.name_en, c.id]));
  console.log('  categories        :', cats.length);

  const imgs = await upsert(sb, 'images', plan.imageUrls.map((url) => ({ url })), 'url');
  const imgId = Object.fromEntries(imgs.map((i) => [i.url, i.id]));
  console.log('  images            :', imgs.length);

  const prodRows = products.map((p) => ({
    id: p.id, name_en: p.name_en, name_ta: p.name_ta || '', name_alt: p.name_alt || '',
    category_id: catId[p.category_en], image_id: p.image ? imgId[p.image] : null,
    origin: p.origin || '', tagline: p.tagline || '', badge: p.badge || '',
    description_en: p.description_en || '', description_ta: p.description_ta || '',
    highlights: p.highlights || [], trust_points: p.trust_points || [],
    harvest_note: p.harvest_note === undefined ? null : p.harvest_note,
    sold_by: p.sold_by, allow_note: p.allow_note !== false, note_hint: p.note_hint || '',
    paired_with: p.paired_with || [], keywords: p.keywords || [], sort: p.sort || 0, is_active: true,
  }));
  await upsert(sb, 'products', prodRows, 'id');
  console.log('  products          :', prodRows.length);

  const packRows = plan.packs.map((k) => ({
    product_id: k.product_id, sort: k.sort, label_en: k.label_en, label_ta: k.label_ta || '',
    quantity: k.quantity, unit: k.unit, is_default: !!k.is_default, popular: !!k.popular, note: k.note || '',
  }));
  await upsert(sb, 'product_packs', packRows, 'product_id,sort');
  console.log('  packs             :', packRows.length);

  const lpRows = [];
  for (const l of locs) {
    for (const p of products) {
      lpRows.push({ location_id: l.id, product_id: p.id, is_available: true, in_stock: p.in_stock !== false, featured: !!p.featured });
    }
  }
  // ignoreDuplicates: never clobber what a vendor changed since the first run.
  await upsert(sb, 'location_products', lpRows, 'location_id,product_id', { ignoreDuplicates: true });
  console.log('  location_products :', lpRows.length);

  await ensureOwner(sb);

  // Verify row counts.
  for (const [t, expect] of [['products', products.length], ['product_packs', packRows.length], ['categories', cats.length], ['images', imgs.length]]) {
    const { count: n, error } = await sb.from(t).select('*', { count: 'exact', head: true });
    if (error) throw new Error('count ' + t + ': ' + error.message);
    console.log(`  verify ${t}: ${n} rows${n >= expect ? ' OK' : ' MISMATCH (expected ' + expect + ')'}`);
  }
  console.log('\nDone. Prices are blank: products stay hidden in the app until a price is entered.');
}

main().catch((e) => { console.error('\nFAILED:', e.message); process.exit(1); });
