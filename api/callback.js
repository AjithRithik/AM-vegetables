// Step 2 of Decap CMS GitHub login: swap GitHub's code for a token and hand it
// back to the CMS window that opened this popup.
const page = (status, payload) => `<!doctype html><html><body><script>
(function () {
  var msg = 'authorization:github:${status}:' + ${JSON.stringify(JSON.stringify(payload))};
  function receive(e) {
    window.opener.postMessage(msg, e.origin);
    window.removeEventListener('message', receive, false);
    window.close();
  }
  window.addEventListener('message', receive, false);
  window.opener.postMessage('authorizing:github', '*');
})();
</script></body></html>`;

module.exports = async (req, res) => {
  const { code, state } = req.query || {};
  const cookie = (req.headers.cookie || '').match(/(?:^|;\s*)oauth_state=([^;]+)/);
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Set-Cookie', 'oauth_state=; Path=/api; HttpOnly; Secure; SameSite=Lax; Max-Age=0');

  if (!code || !state || !cookie || cookie[1] !== state) {
    return res.status(400).send(page('error', { message: 'Invalid login state. Please try again.' }));
  }

  try {
    const r = await fetch('https://github.com/login/oauth/access_token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body: JSON.stringify({
        client_id: process.env.GITHUB_CLIENT_ID,
        client_secret: process.env.GITHUB_CLIENT_SECRET,
        code,
      }),
    });
    const data = await r.json();
    if (!data.access_token) throw new Error(data.error_description || data.error || 'No token returned');
    res.status(200).send(page('success', { token: data.access_token, provider: 'github' }));
  } catch (e) {
    res.status(500).send(page('error', { message: String(e.message || e) }));
  }
};
