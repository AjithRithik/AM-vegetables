// Update existing products. Body: { changes: { "<id>": { in_stock?, featured?, badge?, tagline?,
// packs?: [{quantity,is_default}], imageData?: "data:image/jpeg;base64,..." } } }
const { requireAuth, commitFiles, readProduct, text, cleanPacks, imageFile, ID_RE, json, DIR } = require('../_lib/common');

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  if (!requireAuth(req, res)) return;

  try {
    const changes = (req.body && req.body.changes) || {};
    const ids = Object.keys(changes);
    if (!ids.length || ids.length > 150) return res.status(400).json({ error: 'Nothing to save.' });

    const files = [];
    let inN = 0, outN = 0;
    for (const id of ids) {
      if (!ID_RE.test(id)) return res.status(400).json({ error: 'Bad product id.' });
      const patch = changes[id] || {};
      const p = await readProduct(id);

      if ('in_stock' in patch) { p.in_stock = !!patch.in_stock; p.in_stock ? inN++ : outN++; }
      if ('featured' in patch) p.featured = !!patch.featured;
      if ('badge' in patch) p.badge = text(patch.badge, 40);
      if ('tagline' in patch) p.tagline = text(patch.tagline, 80);
      if ('packs' in patch) p.packs = cleanPacks(patch.packs, p.sold_by, p.packs);
      if (patch.imageData) {
        const img = imageFile(patch.imageData, id);
        files.push(img.file);
        p.image = img.url;
      }
      files.push({ path: `${DIR}/${id}.json`, text: json(p) });
    }

    const parts = [];
    if (inN) parts.push(`${inN} in stock`);
    if (outN) parts.push(`${outN} out of stock`);
    const message = `Staff update: ${ids.length} product${ids.length === 1 ? '' : 's'}${parts.length ? ' (' + parts.join(', ') + ')' : ''}`;
    await commitFiles(files, message);
    res.status(200).json({ ok: true });
  } catch (e) {
    res.status(e.status === 404 ? 404 : 400).json({ error: e.status === 404 ? 'Product not found.' : e.message || 'Could not save.' });
  }
};
