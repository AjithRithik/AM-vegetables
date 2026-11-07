// Owner-only: create a vendor login (mobile number + password) and assign locations, or reset a password.
// Needs env vars on the server: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (never sent to the browser).
// The caller must send their own Supabase session token; we check they are an owner.
const { createClient } = require('@supabase/supabase-js');

const PHONE_DOMAIN = 'phone.am-veg.vercel.app';
const normPhone = (v) => { let d = String(v || '').replace(/\D/g, ''); if (d.length === 10) d = '91' + d; return d; };
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

  const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return res.status(500).json({ error: 'Server is not set up: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing.' });
  const sb = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });

  // 1. who is calling?
  const token = (req.headers.authorization || '').replace(/^Bearer /, '');
  if (!token) return res.status(401).json({ error: 'Please log in again.' });
  const { data: who, error: whoErr } = await sb.auth.getUser(token);
  if (whoErr || !who || !who.user) return res.status(401).json({ error: 'Please log in again.' });
  const { data: me } = await sb.from('profiles').select('role').eq('user_id', who.user.id).maybeSingle();
  if (!me || me.role !== 'owner') return res.status(403).json({ error: 'Only the owner can manage vendors.' });

  // 2. validate input
  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch (_) { body = {}; } }
  body = body || {};
  const phone = normPhone(body.phone);
  const email = phone + '@' + PHONE_DOMAIN;   // internal login id, never emailed
  const name = String(body.name || '').trim().slice(0, 80);
  const password = body.password == null ? '' : String(body.password);
  const locations = Array.isArray(body.locations) ? [...new Set(body.locations.map(String))] : [];
  if (phone.length !== 12) return res.status(400).json({ error: 'Enter a 10-digit mobile number.' });
  if (!locations.length || !locations.every((l) => UUID.test(l))) return res.status(400).json({ error: 'Choose at least one location.' });
  if (password && password.length < 8) return res.status(400).json({ error: 'Password must be at least 8 characters.' });

  try {
    // 3. find or create the login
    let user = null;
    for (let page = 1; !user; page++) {
      const { data, error } = await sb.auth.admin.listUsers({ page, perPage: 200 });
      if (error) throw error;
      user = data.users.find((u) => (u.email || '').toLowerCase() === email) || null;
      if (data.users.length < 200) break;
    }
    let created = false;
    if (!user) {
      if (!password) return res.status(400).json({ error: 'Set a password for the new vendor.' });
      const { data, error } = await sb.auth.admin.createUser({ email, password, email_confirm: true });
      if (error) throw error;
      user = data.user; created = true;
    } else {
      const { data: existing } = await sb.from('profiles').select('role').eq('user_id', user.id).maybeSingle();
      if (existing && existing.role === 'owner') return res.status(400).json({ error: 'That account is an owner.' });
      if (password) {
        const { error } = await sb.auth.admin.updateUserById(user.id, { password });
        if (error) throw error;
      }
    }

    // 4. profile + locations
    const p = await sb.from('profiles').upsert({ user_id: user.id, role: 'vendor', name, email, phone }, { onConflict: 'user_id' });
    if (p.error) throw p.error;
    const d = await sb.from('vendor_locations').delete().eq('user_id', user.id);
    if (d.error) throw d.error;
    const i = await sb.from('vendor_locations').insert(locations.map((location_id) => ({ user_id: user.id, location_id })));
    if (i.error) throw i.error;

    res.status(200).json({ ok: true, user_id: user.id, created, password_changed: !!password });
  } catch (e) {
    res.status(500).json({ error: e.message || 'Could not save the vendor.' });
  }
};
