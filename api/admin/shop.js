// Shop settings for staff: every text setting in content/shop.json (names, taglines, WhatsApp and
// call numbers, hours, open switch, banner, messages, steps, badges, pincodes). The logo image and
// category icons stay owner-only in /admin/.
//   GET  -> { shop: {...} }     POST -> body with any of the same keys
const { requireAuth, gh, BRANCH, commitFiles, text, json } = require('../_lib/common');

const PATH = 'content/shop.json';

async function readShop() {
  const f = await gh('/contents/' + PATH + '?ref=' + BRANCH);
  return JSON.parse(Buffer.from(f.content, 'base64').toString('utf8'));
}

const list = (a) => (Array.isArray(a) ? a : []);

const view = (s) => ({
  name_en: s.name_en || '',
  name_ta: s.name_ta || '',
  badge: s.badge || '',
  splash_tagline_en: s.splash_tagline_en || '',
  splash_tagline_ta: s.splash_tagline_ta || '',
  whatsapp: s.whatsapp || '',
  phone: s.phone || '',
  open_label_en: s.open_label_en || '',
  open_label_ta: s.open_label_ta || '',
  is_open: s.is_open !== false,
  hours: s.hours || '',
  payment_note: s.payment_note || '',
  banner: {
    title_en: (s.banner || {}).title_en || '',
    title_ta: (s.banner || {}).title_ta || '',
    chip: (s.banner || {}).chip || '',
    body: (s.banner || {}).body || '',
  },
  no_payment: {
    title_en: (s.no_payment || {}).title_en || '',
    title_ta: (s.no_payment || {}).title_ta || '',
    body_en: (s.no_payment || {}).body_en || '',
    body_ta: (s.no_payment || {}).body_ta || '',
  },
  how_it_works: list(s.how_it_works).map((x) => ({ title_en: x.title_en || '', title_ta: x.title_ta || '' })),
  footer_badges: list(s.footer_badges).map((x) => ({ text_en: x.text_en || '', text_ta: x.text_ta || '' })),
  pincodes: list(s.pincodes).map((p) => ({ pincode: p.pincode, area: p.area, active: p.active !== false })),
});

function cleanPincodes(input) {
  if (!Array.isArray(input) || input.length > 100) throw new Error('Too many pincodes.');
  const seen = new Set();
  return input.map((p) => {
    const pincode = text(p.pincode, 6);
    if (!/^[0-9]{6}$/.test(pincode)) throw new Error('Pincode must be 6 digits.');
    if (seen.has(pincode)) throw new Error('Pincode ' + pincode + ' is listed twice.');
    seen.add(pincode);
    const area = text(p.area, 60);
    if (!area) throw new Error('Enter an area name for ' + pincode + '.');
    return { pincode, area, active: !!p.active };
  });
}

function cleanWhatsapp(v) {
  const d = String(v ?? '').replace(/\D/g, '');
  if (!/^[0-9]{11,15}$/.test(d)) throw new Error('WhatsApp number needs the country code, e.g. 919840123456.');
  return d;
}

function cleanList(input, max, keys, required) {
  if (!Array.isArray(input) || input.length > max) throw new Error('Too many items (max ' + max + ').');
  return input.map((x) => {
    const o = {};
    for (const [k, len] of keys) o[k] = text(x[k], len);
    if (!o[required]) throw new Error('Fill in the English text or remove the empty row.');
    return o;
  });
}

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (!requireAuth(req, res)) return;

  try {
    if (req.method === 'GET') return res.status(200).json({ shop: view(await readShop()) });
    if (req.method !== 'POST') return res.status(405).json({ error: 'GET or POST only' });

    const patch = req.body || {};
    const s = await readShop();
    const changed = [];

    const str = (k, max, label) => {
      if (!(k in patch)) return;
      const v = text(patch[k], max);
      if (!v) throw new Error(label + ' cannot be empty.');
      s[k] = v;
      changed.push(label.toLowerCase());
    };
    str('name_en', 60, 'Shop name');
    str('name_ta', 80, 'Shop name (Tamil)');
    str('badge', 20, 'Header badge');
    str('splash_tagline_en', 80, 'Tagline');
    str('splash_tagline_ta', 120, 'Tagline (Tamil)');
    str('open_label_en', 40, 'Open label');
    str('open_label_ta', 60, 'Open label (Tamil)');
    if ('whatsapp' in patch) { s.whatsapp = cleanWhatsapp(patch.whatsapp); changed.push('WhatsApp number'); }
    if ('phone' in patch) {
      const ph = text(patch.phone, 20);
      if (ph.replace(/\D/g, '').length < 10) throw new Error('Enter a valid call number.');
      s.phone = ph;
      changed.push('phone');
    }
    if ('is_open' in patch) { s.is_open = !!patch.is_open; changed.push(s.is_open ? 'open' : 'closed'); }
    if ('hours' in patch) { s.hours = text(patch.hours, 60); changed.push('hours'); }
    if ('payment_note' in patch) { s.payment_note = text(patch.payment_note, 120); changed.push('payment note'); }
    if (patch.banner) {
      const b = patch.banner;
      s.banner = {
        ...(s.banner || {}),
        title_en: text(b.title_en, 80),
        title_ta: text(b.title_ta, 120),
        chip: text(b.chip, 40),
        body: text(b.body, 400),
      };
      changed.push('banner');
    }
    if (patch.no_payment) {
      const n = patch.no_payment;
      s.no_payment = {
        ...(s.no_payment || {}),
        title_en: text(n.title_en, 80),
        title_ta: text(n.title_ta, 120),
        body_en: text(n.body_en, 400),
        body_ta: text(n.body_ta, 400),
      };
      changed.push('no-payment message');
    }
    if ('how_it_works' in patch) {
      s.how_it_works = cleanList(patch.how_it_works, 3, [['title_en', 60], ['title_ta', 80]], 'title_en');
      changed.push('steps');
    }
    if ('footer_badges' in patch) {
      s.footer_badges = cleanList(patch.footer_badges, 6, [['text_en', 40], ['text_ta', 60]], 'text_en');
      changed.push('badges');
    }
    if ('pincodes' in patch) { s.pincodes = cleanPincodes(patch.pincodes); changed.push('pincodes'); }

    if (!changed.length) return res.status(400).json({ error: 'Nothing to save.' });
    await commitFiles([{ path: PATH, text: json(s) }], 'Staff update: shop settings (' + changed.join(', ') + ')');
    res.status(200).json({ ok: true, shop: view(s) });
  } catch (e) {
    res.status(400).json({ error: e.message || 'Could not save.' });
  }
};
