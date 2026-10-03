// One-time: split content/products.json into content/products/<id>.json
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, 'content/products');
const { products } = JSON.parse(fs.readFileSync(path.join(root, 'content/products.json'), 'utf8'));
fs.mkdirSync(dir, { recursive: true });
for (const p of products) fs.writeFileSync(path.join(dir, `${p.id}.json`), JSON.stringify(p, null, 2) + '\n');
console.log(`Wrote ${products.length} files to content/products/`);
