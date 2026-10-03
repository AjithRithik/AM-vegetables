const { requireAuth, loadProducts } = require('../_lib/common');

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (!requireAuth(req, res)) return;
  try {
    res.status(200).json({ products: await loadProducts() });
  } catch (e) {
    res.status(500).json({ error: 'Could not load products. ' + (e.message || '') });
  }
};
