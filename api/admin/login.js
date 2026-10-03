const { configured, safeEqual, makeToken } = require('../_lib/common');

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  if (!configured(res)) return;
  const password = String((req.body && req.body.password) || '');
  if (!password || !safeEqual(password, process.env.ADMIN_PASSWORD)) {
    await new Promise((r) => setTimeout(r, 800)); // slow down guessing
    return res.status(401).json({ error: 'Wrong password.' });
  }
  res.status(200).json({ token: makeToken() });
};
