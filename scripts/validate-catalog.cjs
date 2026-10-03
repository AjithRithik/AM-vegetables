const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const products = JSON.parse(fs.readFileSync(path.join(root, 'content/products.json'), 'utf8')).products;
const shop = JSON.parse(fs.readFileSync(path.join(root, 'content/shop.json'), 'utf8'));
const ids = new Set(products.map(p => p.id));
assert.equal(ids.size, products.length, 'Duplicate product IDs');
const categories = new Map();
let images = 0;
for (const p of products) {
  assert.match(p.id, /^[a-z0-9-]+$/);
  for (const key of ['name_en', 'name_ta', 'name_alt', 'category_en', 'category_ta', 'description_en', 'description_ta']) {
    assert.ok(typeof p[key] === 'string' && p[key].trim(), `${p.id}: missing ${key}`);
    assert.ok(!p[key].includes('�') && !p[key].includes('à®'), `${p.id}: damaged encoding`);
  }
  assert.match(p.name_ta, /[\u0B80-\u0BFF]/);
  if (categories.has(p.category_en)) assert.equal(categories.get(p.category_en), p.category_ta);
  categories.set(p.category_en, p.category_ta);
  assert.ok(['weight', 'bunch', 'piece'].includes(p.sold_by));
  assert.ok(p.packs.length > 0);
  assert.equal(p.packs.filter(pack => pack.is_default).length, 1, `${p.id}: select one default pack`);
  for (const pack of p.packs) {
    assert.ok(pack.quantity > 0 && Number.isFinite(pack.quantity));
    assert.ok((p.sold_by === 'weight' ? ['kg', 'g'] : [p.sold_by]).includes(pack.unit));
  }
  for (const id of p.paired_with || []) assert.ok(ids.has(id), `${p.id}: missing paired product ${id}`);
  assert.equal(typeof p.in_stock, 'boolean');
  if (p.image) {
    if (/^https:\/\/res\.cloudinary\.com\//.test(p.image)) {
      assert.ok(p.image.includes('/image/upload/'), `${p.id}: bad Cloudinary image URL`);
    } else {
      assert.ok(p.image.startsWith('/images/uploads/'), `${p.id}: unsupported image path`);
      assert.ok(fs.existsSync(path.join(root, p.image.slice(1))), `${p.id}: missing image file`);
    }
    images++;
  }
}
assert.ok(shop.logo && fs.existsSync(path.join(root, shop.logo.replace(/^\//, ''))), 'Missing shop logo');
if (process.argv.includes('--require-images')) assert.equal(images, products.length, 'Not every product has an image');
console.log(`Validated ${products.length} products, ${categories.size} categories, ${images} images, Tamil text, packs and related IDs.`);
