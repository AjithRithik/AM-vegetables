const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const file = path.join(root, 'content/products.json');
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
let linked = 0;
for (const p of data.products) {
  const folder = '/images/uploads/products/';
  const selected = p.image.startsWith(folder) ? path.basename(p.image, path.extname(p.image)) : p.id;
  let found = false;
  for (const stem of [...new Set([selected, p.id])]) {
    for (const extension of ['jpg', 'png']) {
      const relative = `${folder}${stem}.${extension}`;
      if (fs.existsSync(path.join(root, relative.slice(1)))) {
        p.image = relative;
        linked++;
        found = true;
        break;
      }
    }
    if (found) break;
  }
}
fs.writeFileSync(file, JSON.stringify(data, null, 2) + '\n');
console.log(`Linked ${linked}/${data.products.length} product images.`);
