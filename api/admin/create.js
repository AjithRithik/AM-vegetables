// Add a new product. Body: { name_en, name_ta, category_en, category_ta?, sold_by,
// packs:[{quantity,is_default}], imageData? }
const { requireAuth, commitFiles, loadProducts, gh, text, cleanPacks, imageFile, ID_RE, json, DIR, UNITS } = require('../_lib/common');

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  if (!requireAuth(req, res)) return;

  try {
    const b = req.body || {};
    const name_en = text(b.name_en, 60);
    const name_ta = text(b.name_ta, 60);
    const category_en = text(b.category_en, 40);
    const sold_by = b.sold_by;
    if (!name_en || !name_ta || !category_en) return res.status(400).json({ error: 'Please fill English name, Tamil name and category.' });
    if (!UNITS[sold_by]) return res.status(400).json({ error: 'Choose how it is sold.' });
    if (!/[஀-௿]/.test(name_ta)) return res.status(400).json({ error: 'Tamil name should be written in Tamil.' });

    const id = name_en.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);
    if (!ID_RE.test(id)) return res.status(400).json({ error: 'English name must contain letters or numbers.' });
    try {
      await gh('/contents/' + DIR + '/' + id + '.json');
      return res.status(409).json({ error: `“${name_en}” already exists.` });
    } catch (e) { if (e.status !== 404) throw e; }

    const existing = await loadProducts();
    const known = existing.find((p) => p.category_en === category_en);
    const category_ta = known ? known.category_ta : text(b.category_ta, 40);
    if (!category_ta) return res.status(400).json({ error: 'New category needs a Tamil name too.' });

    const files = [];
    let image = '';
    if (b.imageData) {
      const img = imageFile(b.imageData, id);
      files.push(img.file);
      image = img.url;
    }
    const product = {
      id, name_en, name_ta, name_alt: name_en, category_en, category_ta, image,
      origin: '', tagline: '', badge: '',
      description_en: `${name_en}. Price and availability are confirmed by the shop on WhatsApp.`,
      description_ta: `${name_ta}. விலை மற்றும் இருப்பு வாட்ஸ்அப் மூலம் கடையால் உறுதி செய்யப்படும்.`,
      highlights: [], trust_points: [], harvest_note: '', sold_by,
      packs: cleanPacks(b.packs, sold_by),
      allow_note: true, note_hint: '', featured: false, paired_with: [], in_stock: true,
      sort: 1000, keywords: [...new Set([name_en.toLowerCase(), name_ta])],
    };
    files.push({ path: `${DIR}/${id}.json`, text: json(product) });
    await commitFiles(files, `Staff added product: ${name_en}`);
    res.status(200).json({ ok: true, id });
  } catch (e) {
    res.status(400).json({ error: e.message || 'Could not add product.' });
  }
};
