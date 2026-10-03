// Step 1 of Decap CMS GitHub login: send the editor to GitHub.
// Needs env vars on Vercel: GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET
const crypto = require('crypto');

module.exports = (req, res) => {
  const clientId = process.env.GITHUB_CLIENT_ID;
  if (!clientId) return res.status(500).send('GITHUB_CLIENT_ID is not set');

  const state = crypto.randomBytes(16).toString('hex');
  const scope = (req.query && req.query.scope) || 'repo';
  const url =
    'https://github.com/login/oauth/authorize?' +
    new URLSearchParams({ client_id: clientId, scope, state });

  res.setHeader('Set-Cookie', `oauth_state=${state}; Path=/api; HttpOnly; Secure; SameSite=Lax; Max-Age=600`);
  res.redirect(302, url);
};
