// Merges content/products/*.json into content/products.json (the file the app reads).
// Runs on every Vercel deploy and can be run locally: npm run catalog:build
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const dir = path.join(root, 'content/products');
const products = fs.readdirSync(dir)
  .filter(f => f.endsWith('.json'))
  .map(f => JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')))
  .sort((a, b) => (a.sort ?? 100) - (b.sort ?? 100) || a.id.localeCompare(b.id));
fs.writeFileSync(path.join(root, 'content/products.json'), JSON.stringify({ products }, null, 2) + '\n');
console.log(`Built content/products.json with ${products.length} products`);
