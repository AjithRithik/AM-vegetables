// AM Vegetables admin panel (Supabase).
//   owner  : products (all details + prices for every location), locations, team
//   vendor : stock + prices for their own location(s), their shop details
// Permissions are enforced by Row Level Security in the database, not by this page.
(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const cfg = window.AM_CONFIG || {};
  if (!cfg.anonKey || cfg.anonKey.startsWith('PASTE_')) {
    document.body.textContent = 'Admin is not configured: set anonKey in staff/config.js';
    return;
  }
  const sb = window.supabase.createClient(cfg.url, cfg.anonKey);

  const S = {
    me: null, locations: [], locId: null,
    master: [], cats: [],
    lp: new Map(),        // product_id -> location_products row (current location)
    prices: new Map(),    // pack_id -> number|null (current location)
    view: 'products', q: '', cat: '', tab: 'all',
    refreshCount: () => {},
    of: { status: 'all', loc: '', range: 'all', from: '', to: '', q: '', page: 1 },
    rp: { range: '30d', from: '', to: '', loc: '', mode: 'cd' },
    reloadOrders: null, newCount: 0, topOrderNo: 0, pollReady: false, pollTimer: null,
  };
  const isOwner = () => !!S.me && S.me.role === 'owner';
  const loc = () => S.locations.find((l) => l.id === S.locId);

  // ------------------------------------------------------------------ helpers
  // ------------------------------------------------------------------ icons (static SVG paths only)
  const ICONS = {
    leaf: '<path d="M11 20A7 7 0 019.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10z"/><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"/>',
    pin: '<path d="M20 10c0 6-8 12-8 12S4 16 4 10a8 8 0 0116 0z"/><circle cx="12" cy="10" r="3"/>',
    users: '<path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/>',
    store: '<path d="M3 9l1-5h16l1 5"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/><path d="M3 9a3 3 0 006 0 3 3 0 006 0 3 3 0 006 0"/>',
    search: '<circle cx="11" cy="11" r="8"/><path d="M21 21l-4.3-4.3"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    pencil: '<path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 013 3L7 19l-4 1 1-4z"/>',
    star: '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>',
    logout: '<path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>',
    sliders: '<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"/>',
    x: '<path d="M18 6L6 18M6 6l12 12"/>',
    check: '<path d="M20 6L9 17l-5-5"/>',
    alert: '<circle cx="12" cy="12" r="10"/><path d="M12 8v4M12 16h.01"/>',
    clock: '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
    chat: '<path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z"/>',
    download: '<path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><path d="M7 10l5 5 5-5"/><path d="M12 15V3"/>',
    upload: '<path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><path d="M17 8l-5-5-5 5"/><path d="M12 3v12"/>',
    refresh: '<path d="M23 4v6h-6"/><path d="M1 20v-6h6"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/>',
    image: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/>',
    truck: '<rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/>',
    receipt: '<path d="M4 2v20l3-2 3 2 3-2 3 2 3-2V2l-3 2-3-2-3 2-3-2z"/><path d="M8 9h8M8 13h8"/>',
    phone: '<path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.13.96.36 1.9.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0122 16.92z"/>',
    chart: '<path d="M3 3v18h18"/><path d="M7 15l4-4 3 3 5-6"/>',
    inbox: '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11L2 12v6a2 2 0 002 2h16a2 2 0 002-2v-6l-3.45-6.89A2 2 0 0016.76 4H7.24a2 2 0 00-1.79 1.11z"/>',
  };
  function ico(name, size = 18) {
    const s = document.createElement('span');
    s.className = 'ico';
    s.innerHTML = `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ''}</svg>`;
    return s;
  }

  function el(tag, attrs, ...kids) {
    const n = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (k === 'class') n.className = v;
      else if (k.startsWith('on')) n.addEventListener(k.slice(2), v);
      else if (k === 'value') n.value = v;
      else if (v === true) n.setAttribute(k, '');
      else if (v !== false && v != null) n.setAttribute(k, v);
    }
    for (const kid of kids.flat()) if (kid != null && kid !== false) n.append(kid.nodeType ? kid : document.createTextNode(kid));
    return n;
  }
  function toast(msg, bad) {
    const t = el('div', { class: 'toast' + (bad ? ' bad' : ''), role: 'status' }, ico(bad ? 'alert' : 'check', 18), el('span', null, msg));
    document.body.append(t);
    setTimeout(() => t.remove(), bad ? 5500 : 2400);
  }
  const pageHead = (title, sub, ...acts) => el('div', { class: 'pagehead' },
    el('div', null, el('h1', null, title), sub ? el('div', { class: 'sub' }, sub) : null),
    el('div', { class: 'headacts' }, ...acts));
  const skeleton = (n = 3, h = 140) => el('div', { class: 'cards' }, Array.from({ length: n }, () => el('div', { class: 'skel', style: `height:${h}px` })));
  const emptyState = (icon, text) => el('div', { class: 'empty' }, ico(icon, 34), el('div', null, text));
  const deliveryLine = (s) => {
    const pins = (s.pincodes || []).filter((x) => x.active !== false && x.pincode);
    return pins.length
      ? kv('truck', 'Delivers to ' + pins.length + ' pincode' + (pins.length > 1 ? 's' : '') + ': ' + pins.slice(0, 6).map((x) => x.pincode).join(', ') + (pins.length > 6 ? '…' : ''))
      : kv('truck', 'No delivery pincodes set: orders are accepted from any pincode', true);
  };
  const kv = (icon, text, warn) => el('div', { class: 'kv' + (warn ? ' warn' : '') }, ico(icon, 16), el('span', null, text));
  const stat = (n, label) => el('div', { class: 'stat' }, el('b', null, String(n)), el('small', null, label));
  const tog = (text, checked, fn, disabled) => el('div', { class: 'tog' + (disabled ? ' dis' : '') }, el('span', null, text), sw(checked, fn, disabled));
  const money = (input) => el('div', { class: 'money' }, el('span', { class: 'cur' }, '₹'), input);
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') $('sheetRoot').replaceChildren(); });

  const thumb = (url, w = 200) =>
    url && url.includes('/image/upload/') && !url.includes('/upload/f_auto')
      ? url.replace('/image/upload/', `/image/upload/f_auto,q_auto,c_limit,w_${w}/`) : url || '';
  const slugify = (s) => s.toLowerCase().replace(/&/g, 'and').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const normPhone = (v) => { let d = String(v || '').replace(/\D/g, ''); if (d.length === 10) d = '91' + d; return d; };
  const PHONE_DOMAIN = 'phone.am-veg.vercel.app';
  const phoneEmail = (v) => { const d = normPhone(v); return d.length === 12 ? d + '@' + PHONE_DOMAIN : ''; };
  const showPhone = (d) => (d && d.length === 12 && d.startsWith('91') ? '+91 ' + d.slice(2) : d || '');
  const matches = (p, term) => !term || (p.name_en + ' ' + p.name_ta + ' ' + (p.keywords || []).join(' ')).toLowerCase().includes(term);

  function sw(checked, onchange, disabled) {
    const i = el('input', { type: 'checkbox', checked: !!checked, disabled: !!disabled });
    i.addEventListener('change', () => onchange(i.checked, i));
    return el('label', { class: 'switch' }, i, el('i'));
  }
  async function run(promise, what) {
    const { data, error } = await promise;
    if (error) { toast(`${what || 'Failed'}: ${error.message}`, true); throw error; }
    return data;
  }
  const chunks = (a, n = 200) => Array.from({ length: Math.ceil(a.length / n) }, (_, i) => a.slice(i * n, i * n + n));
  async function upsertAll(table, rows, onConflict, what) {
    for (const part of chunks(rows)) await run(sb.from(table).upsert(part, { onConflict }), what);
  }

  function openSheet(title, build, opts = {}) {
    const root = $('sheetRoot');
    const close = () => root.replaceChildren();
    const body = el('div');
    root.replaceChildren(el('div', { class: 'overlay', onclick: (e) => { if (e.target.classList.contains('overlay') && !opts.sticky) close(); } },
      el('div', { class: 'sheet', role: 'dialog', 'aria-label': title },
        el('div', { class: 'sheethead' }, el('h3', null, title), el('button', { class: 'iconbtn', onclick: close, 'aria-label': 'Close' }, ico('x', 18))),
        body)));
    body.append(...[].concat(build(close)).filter(Boolean));
    return close;
  }
  const sec = (title, ...kids) => el('div', { class: 'sec' }, title ? el('h4', null, title) : null, ...kids);
  const lbl = (t, ta, hint) => el('label', { class: 'lbl' }, t, ta ? el('small', { class: 'ta' }, ' ' + ta) : null, hint ? el('small', null, ' · ' + hint) : null);

  // ------------------------------------------------------------------ auth + boot
  function showLogin(msg) {
    $('appView').hidden = true; $('loginView').hidden = false;
    $('loginErr').textContent = msg || ''; $('pw').value = '';
  }
  async function doLogin() {
    const btn = $('loginBtn'); btn.disabled = true; $('loginErr').textContent = '';
    const raw = $('email').value.trim();
    const email = raw.includes('@') ? raw : phoneEmail(raw);   // owner may still use an email
    if (!email) { btn.disabled = false; $('loginErr').textContent = 'Enter your 10-digit mobile number.'; return; }
    const { error } = await sb.auth.signInWithPassword({ email, password: $('pw').value });
    btn.disabled = false;
    if (error) { $('loginErr').textContent = /invalid login/i.test(error.message) ? 'Wrong mobile number or password.' : error.message; return; }
    await start();
  }
  $('loginBtn').onclick = doLogin;
  $('pw').addEventListener('keydown', (e) => { if (e.key === 'Enter') doLogin(); });
  $('logout').onclick = async () => {
    await sb.auth.signOut(); S.me = null; stopPolling();
    S.view = 'products'; S.q = ''; S.cat = ''; S.tab = 'all';
    $('main').replaceChildren(); $('sheetRoot').replaceChildren();
    showLogin();
  };

  async function start() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) return showLogin();
    const uid = session.user.id;
    const { data: prof, error } = await sb.from('profiles').select('role,name,email,phone').eq('user_id', uid).maybeSingle();
    if (error || !prof) { await sb.auth.signOut(); return showLogin('This account has no admin access. Ask the owner to add you.'); }
    S.me = { id: uid, ...prof };
    await loadLocations();
    if (!S.locations.length) { await sb.auth.signOut(); return showLogin('No location is assigned to this account yet.'); }
    $('loginView').hidden = true; $('appView').hidden = false;
    $('who').textContent = S.me.name || showPhone(S.me.phone) || S.me.email;
    $('whoSub').textContent = isOwner() ? 'Owner' : 'Vendor';
    S.cats = await run(sb.from('categories').select('id,slug,name_en,name_ta,sort').order('sort'), 'Load categories');
    await loadMaster();
    let saved = null; try { saved = localStorage.getItem('am-loc'); } catch (_) {}
    S.locId = S.locations.some((l) => l.id === saved) ? saved : S.locations[0].id;
    // Every login starts on the Products page with clean filters, whatever was open before.
    S.view = 'products'; S.q = ''; S.cat = ''; S.tab = 'all';
    buildChrome();
    await loadLocation();
    startPolling();
  }

  async function loadLocations() {
    if (isOwner()) {
      S.locations = await run(sb.from('locations').select('*').order('sort').order('name_en'), 'Load locations');
    } else {
      const rows = await run(sb.from('vendor_locations').select('location:locations(*)').eq('user_id', S.me.id), 'Load locations');
      S.locations = rows.map((r) => r.location).filter(Boolean).sort((a, b) => a.sort - b.sort);
    }
  }

  async function loadMaster() {
    S.master = await run(sb.from('products')
      .select('*,category:categories(id,name_en,name_ta,sort),image:images(url),packs:product_packs(*)')
      .eq('is_active', true).order('sort'), 'Load products');
    for (const p of S.master) p.packs.sort((a, b) => a.sort - b.sort);
  }

  async function loadLocation() {
    const [lps, prs] = await Promise.all([
      run(sb.from('location_products').select('*').eq('location_id', S.locId), 'Load stock'),
      run(sb.from('location_pack_prices').select('pack_id,price').eq('location_id', S.locId).limit(5000), 'Load prices'),
    ]);
    S.lp = new Map(lps.map((r) => [r.product_id, r]));
    S.prices = new Map(prs.map((r) => [r.pack_id, r.price == null ? null : +r.price]));
    render();
  }

  function buildChrome() {
    const sel = $('locSel');
    sel.replaceChildren(...S.locations.map((l) => el('option', { value: l.id, selected: l.id === S.locId }, l.name_en + (l.is_active ? '' : ' (hidden)'))));
    $('locSel').closest('.locpick').hidden = S.locations.length < 2;
    sel.onchange = async () => {
      S.locId = sel.value;
      try { localStorage.setItem('am-loc', S.locId); } catch (_) {}
      await loadLocation();
    };
    const tabs = [['products', 'leaf', 'Products'], ['orders', 'receipt', 'Orders'], ['reports', 'chart', 'Reports']];
    if (isOwner()) tabs.push(['locations', 'pin', 'Locations'], ['team', 'users', 'Team']); else tabs.push(['shop', 'store', 'My shop']);
    $('nav').replaceChildren(...tabs.map(([v, ic, t]) =>
      el('button', { class: 'navbtn' + (S.view === v ? ' on' : ''), 'data-v': v, onclick: () => { S.view = v; buildChrome(); render(); window.scrollTo(0, 0); } }, ico(ic, 20), el('span', null, t), v === 'orders' ? el('span', { class: 'navbadge', hidden: !S.newCount }, String(S.newCount)) : null)));
    const nm = S.me.name || showPhone(S.me.phone) || S.me.email || 'Admin';
    $('avatar').textContent = nm.trim().charAt(0).toUpperCase() || 'A';
    $('logout').replaceChildren(ico('logout', 18));
  }

  function render() {
    const m = $('main');
    m.replaceChildren();
    ({ products: renderProducts, orders: renderOrders, reports: renderReports, locations: renderLocations, team: renderTeam, shop: renderMyShop }[S.view] || renderProducts)(m);
  }

  // ------------------------------------------------------------------ product helpers
  const sells = (p) => !!(S.lp.get(p.id) && S.lp.get(p.id).is_available);
  const needsPrice = (p) => sells(p) && p.packs.some((k) => S.prices.get(k.id) == null);
  const categoriesInUse = () => [...new Map(S.master.map((p) => [p.category.name_en, p.category])).values()].sort((a, b) => a.sort - b.sort);

  async function saveLP(p, patch) {
    const prev = S.lp.get(p.id);
    const row = { location_id: S.locId, product_id: p.id, is_available: false, in_stock: true, featured: false, ...(prev || {}), ...patch };
    S.lp.set(p.id, row);
    refreshRow(p);
    const { error } = await sb.from('location_products').upsert(
      { location_id: row.location_id, product_id: row.product_id, is_available: row.is_available, in_stock: row.in_stock, featured: row.featured },
      { onConflict: 'location_id,product_id' });
    if (error) { prev ? S.lp.set(p.id, prev) : S.lp.delete(p.id); refreshRow(p); toast('Could not save: ' + error.message, true); }
    S.refreshCount();
  }
  function refreshRow(p) {
    const old = document.querySelector(`.prod[data-pid="${p.id}"]`);
    if (old) old.replaceWith(productRow(p));
  }

  // ------------------------------------------------------------------ PRODUCTS TAB
  function renderProducts(root) {
    const owner = isOwner();
    const q = el('input', { class: 'search-in', type: 'search', placeholder: 'Search products / தேடு…', value: S.q });
    const seg = el('div', { class: 'seg' }, [['all', 'All'], ['on', 'Selling'], ['need', 'Needs price'], ['off', 'Not selling']].map(([v, t]) =>
      el('button', { class: S.tab === v ? 'on' : '', onclick: () => { S.tab = v; render(); } }, t, el('span', { class: 'cnt', 'data-k': v }, '0'))));
    const chips = el('div', { class: 'chips' }, [{ name_en: '' }, ...categoriesInUse()].map((c) =>
      el('button', { class: 'chip' + (S.cat === c.name_en ? ' on' : ''), onclick: () => { S.cat = c.name_en; render(); } }, c.name_en || 'All categories')));
    const progress = el('div', { class: 'card progress' });
    const list = el('div', { class: 'listcard' });
    root.append(
      pageHead('Products', `Prices and availability at ${loc().name_en}`,
        el('button', { class: 'btn', onclick: toolsSheet }, ico('sliders', 16), 'Tools'),
        owner ? el('button', { class: 'btn primary', onclick: () => openProduct(null) }, ico('plus', 16), 'Add product') : null),
      progress,
      el('div', { class: 'toolbar' }, el('label', { class: 'searchbox' }, ico('search', 16), q), seg, chips),
      list);

    S.refreshCount = () => {
      const total = S.master.length, selling = S.master.filter(sells).length, need = S.master.filter(needsPrice).length;
      const counts = { all: total, on: selling, need, off: total - selling };
      seg.querySelectorAll('.cnt').forEach((n) => { n.textContent = counts[n.dataset.k]; });
      const priced = selling - need, pct = selling ? Math.round((priced / selling) * 100) : 0;
      progress.replaceChildren(
        el('div', { class: 'txt' },
          el('b', null, selling ? `${priced} of ${selling} selling products have prices` : 'Nothing is selling here yet'),
          el('div', { class: 'bar' }, el('i', { style: `width:${pct}%` }))),
        need ? el('button', { class: 'btn small', onclick: () => { S.tab = 'need'; render(); } }, `Show ${need} unpriced`)
          : (selling ? el('span', { class: 'pill ok' }, 'All priced') : null));
    };
    function draw() {
      const term = S.q.trim().toLowerCase();
      const items = S.master.filter((p) =>
        (!S.cat || p.category.name_en === S.cat) && matches(p, term) &&
        (S.tab === 'all' || (S.tab === 'on' && sells(p)) || (S.tab === 'off' && !sells(p)) || (S.tab === 'need' && needsPrice(p))));
      list.replaceChildren(...items.map(productRow));
      if (!items.length) list.append(emptyState('inbox', S.tab === 'need' ? 'Every selling product has a price.' : 'No products found'));
    }
    q.addEventListener('input', () => { S.q = q.value; draw(); });
    S.refreshCount();
    draw();
  }

  function productRow(p) {
    const owner = isOwner();
    const r = S.lp.get(p.id), on = sells(p), need = needsPrice(p);
    return el('div', { class: 'prod' + (on ? '' : ' off'), 'data-pid': p.id },
      el('div', { class: 'pmain' },
        p.image ? el('img', { class: 'pthumb', src: thumb(p.image.url), alt: '', loading: 'lazy' }) : el('div', { class: 'pthumb' }, ico('image', 20)),
        el('div', { class: 'pinfo' },
          el('div', { class: 'pname' }, p.name_en),
          el('div', { class: 'pta ta' }, p.name_ta),
          el('div', { class: 'pmeta' },
            el('span', { class: 'pill' }, p.category.name_en),
            need ? el('span', { class: 'pill warn' }, 'Needs price') : null,
            on && r && !r.in_stock ? el('span', { class: 'pill off' }, 'Out of stock') : null))),
      on ? el('div', { class: 'ppacks' }, p.packs.map(priceBox)) : el('div', { class: 'ppacks note' }, 'Not sold at this location'),
      el('div', { class: 'pctl' },
        tog('Selling', on, (v) => saveLP(p, { is_available: v })),
        tog('In stock', on && r && r.in_stock, (v) => saveLP(p, { in_stock: v }), !on),
        el('button', { class: 'iconbtn star' + (r && r.featured ? ' on' : ''), title: 'Featured on home screen', 'aria-label': 'Featured', disabled: !on, onclick: () => saveLP(p, { featured: !(r && r.featured) }) }, ico('star', 18)),
        el('button', { class: 'iconbtn', title: owner ? 'Edit product' : 'Details', 'aria-label': 'Edit', onclick: () => openProduct(p) }, ico('pencil', 17))));
  }

  // One price box. Saves as soon as you leave the box or press Enter. No Save button.
  function priceBox(k) {
    const cur = S.prices.get(k.id);
    const inp = el('input', { class: 'pin-price' + (cur == null ? ' missing' : ''), type: 'number', inputmode: 'decimal', min: '0', step: '0.5', placeholder: '0', 'aria-label': 'Price for ' + k.label_en, value: cur == null ? '' : String(cur) });
    inp.addEventListener('keydown', (e) => {
      if (e.key !== 'Enter') return;
      e.preventDefault();
      const all = [...document.querySelectorAll('.ppacks .pin-price')];
      inp.blur();
      const next = all[all.indexOf(inp) + 1];
      if (next) next.focus();
    });
    inp.addEventListener('change', async () => {
      const raw = inp.value.trim(), num = raw === '' ? null : Number(raw), prev = S.prices.get(k.id) ?? null;
      if (num !== null && (!isFinite(num) || num < 0)) { toast('Enter a valid price.', true); inp.value = prev == null ? '' : String(prev); return; }
      if (num === prev) return;
      const { error } = await sb.from('location_pack_prices').upsert({ location_id: S.locId, pack_id: k.id, price: num }, { onConflict: 'location_id,pack_id' });
      if (error) { toast('Could not save price: ' + error.message, true); inp.value = prev == null ? '' : String(prev); return; }
      S.prices.set(k.id, num);
      inp.classList.toggle('missing', num == null);
      inp.classList.add('saved'); setTimeout(() => inp.classList.remove('saved'), 1200);
      S.refreshCount();
    });
    return el('div', { class: 'pbox' }, el('span', { class: 'cap' }, k.label_en), money(inp));
  }


  // ---- bulk tools
  function toolsSheet() {
    const others = S.locations.filter((l) => l.id !== S.locId);
    const src = el('select', { class: 'field' }, others.map((l) => el('option', { value: l.id }, l.name_en)));
    const mode = el('select', { class: 'field' }, el('option', { value: 'fill' }, 'Only fill empty prices (safe)'), el('option', { value: 'all' }, 'Overwrite all prices'));
    openSheet('Bulk tools · ' + loc().name_en, (close) => [
      others.length ? sec('Copy prices from another location',
        lbl('Copy from'), src, lbl('How'), mode,
        el('p', { class: 'hint' }, 'Only copies prices for products that are selling here.'),
        el('button', { class: 'btn primary block', style: 'margin-top:12px', onclick: async (e) => {
          e.target.disabled = true;
          try {
            const rows = await run(sb.from('location_pack_prices').select('pack_id,price').eq('location_id', src.value).not('price', 'is', null).limit(5000), 'Load prices');
            const sellingPacks = new Set(S.master.filter(sells).flatMap((p) => p.packs.map((k) => k.id)));
            const out = rows.filter((r) => sellingPacks.has(r.pack_id) && (mode.value === 'all' || S.prices.get(r.pack_id) == null))
              .map((r) => ({ location_id: S.locId, pack_id: r.pack_id, price: +r.price }));
            if (!out.length) { toast('Nothing to copy.'); e.target.disabled = false; return; }
            if (!confirm(`Copy ${out.length} prices into ${loc().name_en}?`)) { e.target.disabled = false; return; }
            await upsertAll('location_pack_prices', out, 'location_id,pack_id', 'Copy prices');
            out.forEach((r) => S.prices.set(r.pack_id, r.price));
            close(); render(); toast(`${out.length} prices copied ✓`);
          } catch (_) { e.target.disabled = false; }
        } }, 'Copy prices')) : null,
      sec('Spreadsheet (CSV)',
        el('p', { class: 'hint' }, `Export the ${loc().name_en} price list, fill it in Excel or Google Sheets, then import it back.`),
        el('div', { class: 'acts' },
          el('button', { class: 'btn', onclick: exportCsv }, ico('download', 16), 'Export CSV'),
          el('label', { class: 'btn' }, ico('upload', 16), 'Import CSV', el('input', { type: 'file', accept: '.csv,text/csv', hidden: true, onchange: (e) => importCsv(e.target.files[0], close) })))),
    ]);
  }
  const csvCell = (v) => '"' + String(v ?? '').replace(/"/g, '""') + '"';
  function exportCsv() {
    const lines = [['pack_id', 'product', 'pack', 'price'].join(',')];
    for (const p of S.master.filter(sells)) for (const k of p.packs) lines.push([k.id, p.name_en, k.label_en, S.prices.get(k.id) ?? ''].map(csvCell).join(','));
    const a = el('a', { href: URL.createObjectURL(new Blob(['﻿' + lines.join('\n')], { type: 'text/csv' })), download: `prices-${loc().slug}.csv` });
    document.body.append(a); a.click(); a.remove();
  }
  function parseCsv(text) {
    const rows = []; let row = [], cell = '', q = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (q) { if (c === '"') { if (text[i + 1] === '"') { cell += '"'; i++; } else q = false; } else cell += c; }
      else if (c === '"') q = true;
      else if (c === ',') { row.push(cell); cell = ''; }
      else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; row.push(cell); rows.push(row); row = []; cell = ''; }
      else cell += c;
    }
    if (cell || row.length) { row.push(cell); rows.push(row); }
    return rows;
  }
  async function importCsv(file, close) {
    if (!file) return;
    const rows = parseCsv((await file.text()).replace(/^﻿/, '')).filter((r) => r.some((c) => c.trim()));
    const head = rows.shift().map((h) => h.trim().toLowerCase());
    const ci = head.indexOf('pack_id'), pi = head.indexOf('price');
    if (ci < 0 || pi < 0) return toast('CSV needs pack_id and price columns. Use Export first.', true);
    const valid = new Set(S.master.flatMap((p) => p.packs.map((k) => k.id)));
    const out = []; let bad = 0;
    for (const r of rows) {
      const id = (r[ci] || '').trim(), v = (r[pi] || '').trim();
      if (!id) continue;
      if (!valid.has(id) || (v !== '' && (!isFinite(+v) || +v < 0))) { bad++; continue; }
      const num = v === '' ? null : +v;
      if (num === (S.prices.get(id) ?? null)) continue;
      out.push({ location_id: S.locId, pack_id: id, price: num });
    }
    if (!out.length) return toast(bad ? `${bad} rows skipped, nothing to change.` : 'No price changes found.', !!bad);
    if (!confirm(`Apply ${out.length} price changes to ${loc().name_en}?${bad ? ` (${bad} invalid rows skipped)` : ''}`)) return;
    try {
      await upsertAll('location_pack_prices', out, 'location_id,pack_id', 'Import prices');
      out.forEach((r) => S.prices.set(r.pack_id, r.price));
      close(); render(); toast(`${out.length} prices updated ✓`);
    } catch (_) { /* toast shown */ }
  }

  // ------------------------------------------------------------------ PRODUCT EDITOR
  const PRESETS = {
    weight: [['100 g', 'g', 100], ['250 g', 'g', 250], ['500 g', 'g', 500], ['1 kg', 'kg', 1], ['2 kg', 'kg', 2], ['5 kg', 'kg', 5]],
    piece: [['1 piece', 'piece', 1], ['2 pieces', 'piece', 2], ['3 pieces', 'piece', 3], ['6 pieces', 'piece', 6], ['12 pieces', 'piece', 12]],
    bunch: [['1 bunch', 'bunch', 1], ['2 bunches', 'bunch', 2], ['3 bunches', 'bunch', 3]],
  };
  function autoLabel(v, u) {
    const n = +v;
    if (!(n > 0)) return { en: '', ta: '' };
    if (u === 'g') return { en: `${n} g`, ta: n === 500 ? 'அரை கிலோ' : `${n} கிராம்` };
    if (u === 'kg') return { en: `${n} kg`, ta: `${n} கிலோ` };
    if (u === 'piece') return { en: `${n} ${n === 1 ? 'Piece' : 'Pieces'}`, ta: `${n} எண்ணம்` };
    return { en: `${n} ${n === 1 ? 'Bunch' : 'Bunches'}`, ta: `${n} கட்டு` };
  }
  const packQty = (pk) => (pk.u === 'g' ? +pk.v / 1000 : +pk.v);
  const packUnit = (pk) => (pk.u === 'g' ? 'kg' : pk.u);
  const unitsFor = (soldBy) => (soldBy === 'weight' ? ['g', 'kg'] : [soldBy]);

  async function openProduct(p) {
    const owner = isOwner();
    if (!owner && !p) return;
    let lpRows = [], prRows = [];
    if (p) {
      try {
        lpRows = await run(sb.from('location_products').select('*').eq('product_id', p.id), 'Load product');
        const ids = p.packs.map((k) => k.id);
        if (ids.length) prRows = await run(sb.from('location_pack_prices').select('location_id,pack_id,price').in('pack_id', ids).limit(5000), 'Load prices');
      } catch (_) { return; }
    }
    const lpBy = new Map(lpRows.map((r) => [r.location_id, r]));
    const priceBy = new Map(prRows.map((r) => [r.location_id + '|' + r.pack_id, r.price]));
    const cols = S.locations;

    const d = {
      name_en: p ? p.name_en : '', name_ta: p ? p.name_ta : '', name_alt: p ? p.name_alt : '',
      category_id: p ? p.category.id : '', newCat: { en: '', ta: '' },
      image_url: p && p.image ? p.image.url : '',
      sold_by: p ? p.sold_by : 'weight',
      description_en: p ? p.description_en : '', description_ta: p ? p.description_ta : '',
      tagline: p ? p.tagline : '', badge: p ? p.badge : '', origin: p ? p.origin : '', note_hint: p ? p.note_hint : '',
      allow_note: p ? p.allow_note : true,
      avail: Object.fromEntries(cols.map((c) => [c.id, p ? !!(lpBy.get(c.id) || {}).is_available : c.id === S.locId])),
      packs: [],
    };
    const mkPack = (u, v, src) => {
      const lab = autoLabel(v, u);
      return {
        id: src ? src.id : null, u, v: String(v),
        label_en: src ? src.label_en : lab.en, label_ta: src ? src.label_ta : lab.ta, touched: !!src,
        is_default: src ? !!src.is_default : false,
        prices: Object.fromEntries(cols.map((c) => { const x = src ? priceBy.get(c.id + '|' + src.id) : null; return [c.id, x == null ? '' : String(+x)]; })),
      };
    };
    if (p) {
      d.packs = p.packs.map((k) => (k.unit === 'kg' && k.quantity < 1 ? mkPack('g', Math.round(k.quantity * 1000), k) : mkPack(k.unit, k.quantity, k)));
    } else {
      d.packs = [mkPack('g', 500), mkPack('kg', 1)];
      d.packs[0].is_default = true;
    }

    const basicsLocked = !owner;
    const packsBox = el('div');
    const availBox = el('div', { class: 'sellrow' });
    const catExtra = el('div');
    const preview = el('div', { class: 'pthumb' }, '🥬');
    const input = (key, attrs) => {
      const { tag, ...rest } = attrs || {};
      const i = el(tag || 'input', { class: 'field', value: d[key], disabled: basicsLocked, ...rest });
      i.addEventListener('input', () => { d[key] = i.value; });
      return i;
    };

    function drawPreview() {
      preview.replaceChildren(d.image_url ? el('img', { src: thumb(d.image_url, 200), alt: '', style: 'width:100%;height:100%;object-fit:cover;border-radius:14px' }) : '🥬');
    }
    function drawAvail() {
      availBox.replaceChildren(...cols.map((c) => {
        const i = el('input', { type: 'checkbox', checked: d.avail[c.id] });
        i.addEventListener('change', () => { d.avail[c.id] = i.checked; drawPacks(); });
        return el('label', null, i, c.name_en);
      }));
    }
    function drawPacks() {
      packsBox.replaceChildren();
      const sorted = d.packs;
      sorted.forEach((pk) => {
        const head = owner ? el('div', { class: 'head' },
          (() => { const q = el('input', { class: 'field q', type: 'number', inputmode: 'decimal', min: '0', step: 'any', value: pk.v, placeholder: 'Qty' });
            q.addEventListener('input', () => { pk.v = q.value; relabel(pk); }); return q; })(),
          (() => { const s = el('select', { class: 'field' }, unitsFor(d.sold_by).map((u) => el('option', { value: u, selected: u === pk.u }, u)));
            s.addEventListener('change', () => { pk.u = s.value; relabel(pk); }); return s; })(),
          el('span', { style: 'flex:1' }),
          el('button', { class: 'btn small danger', title: 'Remove size', onclick: () => { d.packs = d.packs.filter((x) => x !== pk); if (!d.packs.some((x) => x.is_default) && d.packs[0]) d.packs[0].is_default = true; drawPacks(); } }, '✕'))
          : el('div', { class: 'head' }, el('b', null, pk.label_en));
        let en, ta;
        const names = owner ? el('div', { class: 'two', style: 'margin-top:8px' },
          (en = el('input', { class: 'field', value: pk.label_en, placeholder: 'Label (English)' })),
          (ta = el('input', { class: 'field ta', value: pk.label_ta, placeholder: 'லேபிள் (தமிழ்)' }))) : null;
        function relabel(x) {
          if (x.touched) return;
          const a = autoLabel(x.v, x.u); x.label_en = a.en; x.label_ta = a.ta;
          if (en) { en.value = a.en; ta.value = a.ta; }
        }
        if (en) {
          en.addEventListener('input', () => { pk.label_en = en.value; pk.touched = true; });
          ta.addEventListener('input', () => { pk.label_ta = ta.value; pk.touched = true; });
        }
        const prices = el('div', { class: 'plocs' }, cols.map((c) => {
          const on = d.avail[c.id];
          const i = el('input', { class: 'pin-price' + (on && pk.prices[c.id] === '' ? ' missing' : ''), type: 'number', inputmode: 'decimal', min: '0', step: '0.5', placeholder: on ? '0' : '—', value: pk.prices[c.id], disabled: !on });
          i.addEventListener('input', () => { pk.prices[c.id] = i.value; i.classList.toggle('missing', i.value === ''); });
          return el('div', { class: 'pbox' + (on ? '' : ' na') }, el('span', { class: 'cap' }, c.name_en), money(i));
        }));
        const def = owner ? el('label', { class: 'def' },
          (() => { const r = el('input', { type: 'radio', name: 'defpack', checked: pk.is_default });
            r.addEventListener('change', () => { d.packs.forEach((x) => { x.is_default = x === pk; }); }); return r; })(), 'Default size shown first') : null;
        packsBox.append(el('div', { class: 'packcard' }, head, names, prices, def));
      });
      if (owner) {
        packsBox.append(el('div', { class: 'presets' },
          el('small', { style: 'width:100%' }, 'Add a size:'),
          ...(PRESETS[d.sold_by] || []).map(([t, u, v]) => el('button', { class: 'chip', onclick: () => {
            if (d.packs.some((x) => x.u === u && +x.v === v)) return toast('That size is already added.');
            d.packs.push(mkPack(u, v)); d.packs.sort((a, b) => packQty(a) - packQty(b)); drawPacks();
          } }, '＋ ' + t)),
          el('button', { class: 'chip', onclick: () => { d.packs.push(mkPack(unitsFor(d.sold_by)[0], '')); drawPacks(); } }, '＋ Custom')));
      }
    }
    function drawCat() {
      catExtra.replaceChildren();
      if (d.category_id === '__new') {
        const en = el('input', { class: 'field', placeholder: 'New category (English)', value: d.newCat.en });
        const ta = el('input', { class: 'field ta', placeholder: 'தமிழ் பெயர்', value: d.newCat.ta });
        en.addEventListener('input', () => { d.newCat.en = en.value; }); ta.addEventListener('input', () => { d.newCat.ta = ta.value; });
        catExtra.append(el('div', { class: 'two', style: 'margin-top:8px' }, en, ta));
      }
    }

    const catSel = el('select', { class: 'field', disabled: basicsLocked },
      el('option', { value: '' }, 'Choose category…'),
      ...S.cats.map((c) => el('option', { value: c.id, selected: c.id === d.category_id }, c.name_en)),
      owner ? el('option', { value: '__new' }, '＋ New category…') : null);
    catSel.addEventListener('change', () => { d.category_id = catSel.value; drawCat(); });

    const soldSeg = el('div', { class: 'seg' }, [['weight', 'By weight'], ['piece', 'By piece'], ['bunch', 'By bunch']].map(([v, t]) => {
      const b = el('button', { class: d.sold_by === v ? 'on' : '', disabled: basicsLocked, onclick: () => {
        if (d.sold_by === v) return;
        if (d.packs.length && !confirm('Changing this replaces the sizes below. Continue?')) return;
        d.sold_by = v;
        const first = PRESETS[v][v === 'weight' ? 2 : 0];
        d.packs = [mkPack(first[1], first[2])]; d.packs[0].is_default = true;
        soldSeg.querySelectorAll('button').forEach((x) => x.classList.remove('on')); b.classList.add('on');
        drawPacks();
      } }, t);
      return b;
    }));

    const imgIn = el('input', { class: 'field', value: d.image_url, placeholder: 'https://res.cloudinary.com/…', disabled: basicsLocked });
    imgIn.addEventListener('input', () => { d.image_url = imgIn.value.trim(); drawPreview(); });
    const up = owner && cfg.cloudinary && cfg.cloudinary.preset ? el('label', { class: 'btn small', style: 'margin-top:8px;display:inline-block' }, ico('upload', 16), 'Upload photo',
      el('input', { type: 'file', accept: 'image/*', hidden: true, onchange: async (e) => {
        const f = e.target.files[0]; if (!f) return;
        const fd = new FormData(); fd.append('file', f); fd.append('upload_preset', cfg.cloudinary.preset); fd.append('folder', 'am-veg/products');
        try {
          const r = await fetch(`https://api.cloudinary.com/v1_1/${cfg.cloudinary.cloud}/image/upload`, { method: 'POST', body: fd });
          const j = await r.json(); if (!r.ok) throw new Error((j.error && j.error.message) || 'Upload failed');
          d.image_url = j.secure_url; imgIn.value = d.image_url; drawPreview(); toast('Photo uploaded ✓');
        } catch (err) { toast(err.message, true); }
      } })) : null;

    drawPreview(); drawAvail(); drawPacks(); drawCat();

    async function save(close, btn) {
      const name = d.name_en.trim();
      if (owner) {
        if (!name) return toast('Enter the product name.', true);
        if (!d.category_id) return toast('Choose a category.', true);
        if (d.category_id === '__new' && !d.newCat.en.trim()) return toast('Enter the new category name.', true);
        if (!d.packs.length) return toast('Add at least one size.', true);
        for (const pk of d.packs) if (!(packQty(pk) > 0)) return toast('Every size needs a quantity.', true);
        const keys = d.packs.map((x) => packQty(x) + packUnit(x));
        if (new Set(keys).size !== keys.length) return toast('Two sizes are the same. Remove one.', true);
        if (d.packs.some((x) => !x.label_en.trim())) return toast('Every size needs a label.', true);
      }
      for (const pk of d.packs) for (const c of cols) {
        const v = pk.prices[c.id];
        if (d.avail[c.id] && v !== '' && (!isFinite(+v) || +v < 0)) return toast('Prices must be numbers.', true);
      }
      btn.disabled = true;
      try {
        let productId = p ? p.id : null;
        let packRows = p ? p.packs.map((k) => k) : [];
        if (owner) {
          let catId = d.category_id;
          if (catId === '__new') {
            const [c] = await run(sb.from('categories').insert({ slug: slugify(d.newCat.en) || 'category', name_en: d.newCat.en.trim(), name_ta: d.newCat.ta.trim(), sort: S.cats.length + 1 }).select(), 'Create category');
            catId = c.id; S.cats.push(c);
          }
          let imageId = null;
          if (d.image_url) {
            const [im] = await run(sb.from('images').upsert({ url: d.image_url }, { onConflict: 'url' }).select(), 'Save photo');
            imageId = im.id;
          }
          const fields = {
            name_en: name, name_ta: d.name_ta.trim(), name_alt: d.name_alt.trim(), category_id: catId, image_id: imageId,
            sold_by: d.sold_by, description_en: d.description_en.trim(), description_ta: d.description_ta.trim(),
            tagline: d.tagline.trim(), badge: d.badge.trim(), origin: d.origin.trim(), note_hint: d.note_hint.trim(), allow_note: d.allow_note,
          };
          if (p) {
            await run(sb.from('products').update(fields).eq('id', p.id), 'Save product');
          } else {
            let base = slugify(name) || 'product', id = base, n = 2;
            const taken = new Set(S.master.map((x) => x.id));
            while (taken.has(id)) id = base + '-' + n++;
            const maxSort = S.master.reduce((m, x) => Math.max(m, x.sort || 0), 0);
            await run(sb.from('products').insert({ id, sort: maxSort + 10, keywords: [name.toLowerCase(), d.name_ta.trim()].filter(Boolean), ...fields }), 'Create product');
            productId = id;
          }
          // sizes: remove deleted, move existing out of the way, add new, set final order
          d.packs.sort((a, b) => packQty(a) - packQty(b));
          const keepIds = new Set(d.packs.filter((x) => x.id).map((x) => x.id));
          const gone = (p ? p.packs : []).filter((k) => !keepIds.has(k.id)).map((k) => k.id);
          if (gone.length) await run(sb.from('product_packs').delete().in('id', gone), 'Remove sizes');
          if (!d.packs.some((x) => x.is_default)) d.packs[0].is_default = true;
          const toRow = (x, i) => ({ product_id: productId, label_en: x.label_en.trim(), label_ta: x.label_ta.trim(), quantity: packQty(x), unit: packUnit(x), is_default: !!x.is_default, sort: i });
          const existing = d.packs.map((x, i) => ({ x, i })).filter(({ x }) => x.id);
          if (existing.length) await run(sb.from('product_packs').upsert(existing.map(({ x, i }) => ({ id: x.id, ...toRow(x, 1000 + i) })), { onConflict: 'id' }), 'Save sizes');
          const fresh = d.packs.map((x, i) => ({ x, i })).filter(({ x }) => !x.id);
          if (fresh.length) {
            const created = await run(sb.from('product_packs').insert(fresh.map(({ x, i }) => toRow(x, i))).select(), 'Add sizes');
            created.forEach((row) => { const f = fresh.find(({ i }) => i === row.sort); if (f) f.x.id = row.id; });
          }
          if (existing.length) await run(sb.from('product_packs').upsert(existing.map(({ x, i }) => ({ id: x.id, ...toRow(x, i) })), { onConflict: 'id' }), 'Order sizes');
          packRows = d.packs;
        }
        // availability + prices per location
        const lpOut = cols.map((c) => {
          const prev = lpBy.get(c.id) || {};
          return { location_id: c.id, product_id: productId, is_available: !!d.avail[c.id], in_stock: prev.in_stock ?? true, featured: prev.featured ?? false };
        });
        await upsertAll('location_products', lpOut, 'location_id,product_id', 'Save availability');
        const prOut = [];
        for (const pk of d.packs) for (const c of cols) {
          if (!d.avail[c.id]) continue;
          const v = pk.prices[c.id], had = priceBy.get(c.id + '|' + pk.id);
          if (v === '' && had == null) continue;
          if (!pk.id) continue;
          prOut.push({ location_id: c.id, pack_id: pk.id, price: v === '' ? null : +v });
        }
        if (prOut.length) await upsertAll('location_pack_prices', prOut, 'location_id,pack_id', 'Save prices');
        close();
        await loadMaster(); await loadLocation();
        toast(p ? 'Saved ✓' : 'Product added ✓');
      } catch (_) { btn.disabled = false; }
    }

    openSheet(p ? (owner ? 'Edit product' : p.name_en) : 'Add product', (close) => {
      const saveBtn = el('button', { class: 'btn primary', onclick: (e) => save(close, e.target) }, 'Save');
      return [
        sec(owner ? 'Product' : null,
          owner ? null : el('p', { class: 'hint' }, 'Only the owner can change name, photo and sizes. You can set where it sells and its prices.'),
          el('div', { class: 'photo' }, preview, el('div', { class: 'col' }, lbl('Photo link'), imgIn, up)),
          lbl('Name', 'English'), input('name_en', { placeholder: 'e.g. Country Tomato' }),
          lbl('Name', 'தமிழ்'), input('name_ta', { class: 'field ta', placeholder: 'நாட்டு தக்காளி' }),
          lbl('Category', 'வகை'), catSel, catExtra,
          lbl('Sold', 'விற்பனை முறை'), soldSeg),
        sec('Where it sells', el('p', { class: 'hint' }, 'Tick the locations that sell this product.'), availBox),
        sec('Sizes & prices', el('p', { class: 'hint' }, 'Enter the price for each size in each location. Leave blank to hide that size.'), packsBox),
        owner ? el('div', { class: 'sec' }, el('details', null, el('summary', null, 'More details (optional)'),
          lbl('Short line'), input('tagline', { placeholder: 'e.g. Firm & Juicy' }),
          lbl('Card badge'), input('badge', { placeholder: 'e.g. Fresh Harvest' }),
          lbl('Origin / farm'), input('origin', { placeholder: 'e.g. Dharmapuri Farm' }),
          lbl('Description', 'English'), input('description_en', { tag: 'textarea' }),
          lbl('Description', 'தமிழ்'), input('description_ta', { tag: 'textarea', class: 'field ta' }),
          lbl('Hint for customer note', null, 'shown in the note box'), input('note_hint', { placeholder: 'e.g. Tell us your size preference' }))) : null,
        el('div', { class: 'sheetfoot' },
          owner && p ? el('button', { class: 'btn danger', onclick: async () => {
            if (!confirm(`Remove "${p.name_en}" from ALL locations? You can't undo this from the panel.`)) return;
            await run(sb.from('products').update({ is_active: false }).eq('id', p.id), 'Remove product');
            close(); await loadMaster(); await loadLocation(); toast('Product removed');
          } }, 'Remove') : null,
          saveBtn),
      ];
    }, { sticky: true });
  }

  // ------------------------------------------------------------------ LOCATIONS (owner)
  // ------------------------------------------------------------------ ORDERS
  const ORDER_STATUS = {
    new: ['New', 'warn'], confirmed: ['Confirmed', 'ok'], delivered: ['Delivered', ''], cancelled: ['Cancelled', 'off'],
  };
  const timeAgo = (iso) => {
    const s = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
    if (s < 60) return 'just now';
    if (s < 3600) return Math.floor(s / 60) + ' min ago';
    if (s < 86400) return Math.floor(s / 3600) + ' h ago';
    return new Date(iso).toLocaleDateString(undefined, { day: 'numeric', month: 'short' });
  };

  function setBadge(n) {
    S.newCount = n;
    const b = document.querySelector('#nav .navbtn[data-v="orders"] .navbadge');
    if (b) { b.textContent = n > 99 ? '99+' : String(n); b.hidden = !n; }
    document.title = (n ? `(${n}) ` : '') + 'AM Vegetables · Admin';
  }
  function beep() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const o = ctx.createOscillator(), g = ctx.createGain();
      o.connect(g); g.connect(ctx.destination); o.type = 'sine'; o.frequency.value = 880;
      g.gain.setValueAtTime(0.2, ctx.currentTime); g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5);
      o.start(); o.stop(ctx.currentTime + 0.5);
    } catch (_) { /* browsers block sound until the page has been clicked once */ }
  }
  // Checks for new orders every 30 seconds while the panel is open.
  async function pollOrders() {
    if (!S.me) return;
    const { data, error } = await sb.from('orders').select('order_no').eq('status', 'new').order('order_no', { ascending: false }).limit(100);
    if (error) return;   // orders table not created yet, or offline: stay quiet
    const top = data.length ? data[0].order_no : 0;
    if (S.pollReady && top > S.topOrderNo) {
      const fresh = data.filter((r) => r.order_no > S.topOrderNo).length;
      toast(`${fresh} new order${fresh > 1 ? 's' : ''}!`);
      beep();
      if (S.view === 'orders' && S.reloadOrders) S.reloadOrders();
    }
    S.topOrderNo = Math.max(S.topOrderNo, top);
    S.pollReady = true;
    setBadge(data.length);
  }
  function startPolling() {
    stopPolling();
    S.topOrderNo = 0; S.pollReady = false;
    pollOrders();
    S.pollTimer = setInterval(pollOrders, 30000);
  }
  function stopPolling() { if (S.pollTimer) clearInterval(S.pollTimer); S.pollTimer = null; setBadge(0); }

  async function setOrderStatus(o, status) {
    const { error } = await sb.from('orders').update({ status }).eq('id', o.id);
    if (error) return toast('Could not update: ' + error.message, true);
    o.status = status;
    toast(`Order #${o.order_no} ${ORDER_STATUS[status][0].toLowerCase()}`);
    pollOrders();
    $('sheetRoot').replaceChildren();
    if (S.view === 'orders' && S.reloadOrders) S.reloadOrders(); else render();
  }

  function orderCard(o) {
    const loc = S.locations.find((l) => l.id === o.location_id);
    const [stText, stCls] = ORDER_STATUS[o.status] || [o.status, ''];
    const digits = (o.customer_phone || '').replace(/\D/g, '');
    const wa = digits.length === 10 ? '91' + digits : digits;
    const items = (o.items || []).slice().sort((a, b) => a.name_en.localeCompare(b.name_en));
    const btn = (label, status, cls) => el('button', { class: 'btn small ' + (cls || ''), onclick: () => setOrderStatus(o, status) }, label);
    return el('div', { class: 'card ocard' + (o.status === 'new' ? ' isnew' : '') },
      el('div', { class: 'lhead' },
        el('div', null,
          el('h3', null, '#' + o.order_no, ' ', el('span', { class: 'pill ' + stCls }, stText)),
          el('div', { class: 'hint', style: 'margin:2px 0 0' }, [loc ? loc.name_en : '', timeAgo(o.created_at)].filter(Boolean).join(' · '))),
        el('div', { class: 'ototal' }, '₹' + Number(o.total).toLocaleString('en-IN'))),
      el('div', { class: 'kv' }, ico('users', 16), el('span', null, el('b', null, o.customer_name), ' · ', el('a', { href: 'tel:' + o.customer_phone }, o.customer_phone), o.alt_phone ? ' / ' + o.alt_phone : '')),
      el('div', { class: 'kv' }, ico('pin', 16), el('span', null,
        [o.address, o.landmark ? 'Landmark: ' + o.landmark : '', o.pincode].filter(Boolean).join(' · '),
        o.map_link ? [' ', el('a', { href: o.map_link, target: '_blank', rel: 'noopener' }, 'Open map')] : null)),
      o.notes ? el('div', { class: 'kv' }, ico('chat', 16), el('span', { style: 'font-style:italic' }, '“' + o.notes + '”')) : null,
      el('div', { class: 'oitems' }, items.map((i) => el('div', { class: 'oitem' },
        el('span', { class: 'q' }, i.quantity + ' ×'),
        el('span', { class: 'n' }, i.name_en + ' · ' + i.pack_label, i.note ? el('small', null, ' (' + i.note + ')') : null),
        el('span', { class: 'p' }, '₹' + Number(i.line_total).toLocaleString('en-IN'))))),
      el('div', { class: 'acts' },
        o.status === 'new' ? [btn('Confirm order', 'confirmed', 'primary'), btn('Cancel', 'cancelled', 'danger')] : null,
        o.status === 'confirmed' ? [btn('Mark delivered', 'delivered', 'primary'), btn('Cancel', 'cancelled', 'danger')] : null,
        o.status === 'delivered' || o.status === 'cancelled' ? btn('Reopen', 'new') : null,
        el('a', { class: 'btn small', href: 'https://wa.me/' + wa + '?text=' + encodeURIComponent(`Hello ${o.customer_name}, this is about your AM Vegetables order #${o.order_no}.`), target: '_blank', rel: 'noopener' }, ico('chat', 14), 'WhatsApp'),
        el('a', { class: 'btn small', href: 'tel:' + o.customer_phone }, ico('phone', 14), 'Call')));
  }

  // ---------------------------------------------------------------- shared: dates, filters, exports
  const PAGE_SIZE = 20;
  const STATUS_KEYS = ['new', 'confirmed', 'delivered', 'cancelled'];
  const DATE_PRESETS = [['today', 'Today'], ['7d', 'Last 7 days'], ['30d', 'Last 30 days'], ['month', 'This month'], ['lastmonth', 'Last month'], ['all', 'All time'], ['custom', 'Custom dates']];
  const inr = (n) => '₹' + Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: Number.isInteger(Number(n || 0)) ? 0 : 2, maximumFractionDigits: 2 });
  const pad2 = (n) => String(n).padStart(2, '0');
  const ymd = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
  const hm = (d) => `${pad2(d.getHours())}:${pad2(d.getMinutes())}`;
  const when = (iso) => new Date(iso).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });

  // { from, to } as Dates ("to" is exclusive), or null for all time
  function rangeFor(preset, from, to) {
    const now = new Date();
    const sod = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const add = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
    switch (preset) {
      case 'today': return { from: sod, to: add(sod, 1) };
      case '7d': return { from: add(sod, -6), to: add(sod, 1) };
      case '30d': return { from: add(sod, -29), to: add(sod, 1) };
      case 'month': return { from: new Date(now.getFullYear(), now.getMonth(), 1), to: new Date(now.getFullYear(), now.getMonth() + 1, 1) };
      case 'lastmonth': return { from: new Date(now.getFullYear(), now.getMonth() - 1, 1), to: new Date(now.getFullYear(), now.getMonth(), 1) };
      case 'custom': {
        const f = from ? new Date(from + 'T00:00:00') : null, t = to ? new Date(to + 'T00:00:00') : null;
        if (!f && !t) return null;
        return { from: f || new Date(2000, 0, 1), to: add(t || sod, 1) };
      }
      default: return null;
    }
  }

  // A date-range picker. f = { range, from, to }. Calls onChange() whenever it changes.
  function dateControls(f, onChange) {
    const custom = el('span', { class: 'datepair', hidden: f.range !== 'custom' },
      el('input', { class: 'field slim', type: 'date', value: f.from || '', 'aria-label': 'From date', onchange: (e) => { f.from = e.target.value; onChange(); } }),
      el('span', { class: 'muted' }, 'to'),
      el('input', { class: 'field slim', type: 'date', value: f.to || '', 'aria-label': 'To date', onchange: (e) => { f.to = e.target.value; onChange(); } }));
    const sel = el('select', { class: 'field slim', 'aria-label': 'Date range', onchange: (e) => { f.range = e.target.value; custom.hidden = f.range !== 'custom'; onChange(); } },
      DATE_PRESETS.map(([v, t]) => el('option', { value: v, selected: f.range === v }, t)));
    return el('span', { class: 'datectl' }, sel, custom);
  }

  // Orders query with the current filters. status: 'all' | one status | array of statuses.
  function ordersQuery(f, status, select, opts) {
    let q = sb.from('orders').select(select, opts);
    if (Array.isArray(status)) q = q.in('status', status); else if (status && status !== 'all') q = q.eq('status', status);
    if (f.loc) q = q.eq('location_id', f.loc);
    const r = rangeFor(f.range, f.from, f.to);
    if (r) q = q.gte('created_at', r.from.toISOString()).lt('created_at', r.to.toISOString());
    const term = (f.q || '').replace(/[,()*%\\]/g, ' ').trim();
    if (term) {
      const parts = [`customer_name.ilike.%${term}%`, `customer_phone.ilike.%${term}%`];
      if (/^\d{1,12}$/.test(term)) parts.push(`order_no.eq.${term}`);
      q = q.or(parts.join(','));
    }
    return q;
  }
  // Every order matching the filters, newest first (pages of 500 behind the scenes).
  async function fetchAllOrders(f, status) {
    const out = [], step = 500;
    for (let from = 0; from < 50000; from += step) {
      const { data, error } = await ordersQuery(f, status, '*,items:order_items(*)').order('created_at', { ascending: false }).range(from, from + step - 1);
      if (error) throw error;
      out.push(...data);
      if (data.length < step) break;
    }
    return out;
  }

  const locName = (id) => (S.locations.find((l) => l.id === id) || {}).name_en || '';
  const categoryOf = (productId) => { const p = S.master.find((x) => x.id === productId); return p ? p.category.name_en : 'Other'; };
  const itemsText = (o) => (o.items || []).map((i) => `${i.quantity} x ${i.name_en} (${i.pack_label})`).join('; ');

  const ORDER_HEAD = ['Order no', 'Date', 'Time', 'Location', 'Status', 'Customer', 'Phone', 'Alt phone', 'Address', 'Landmark', 'Pincode', 'Notes', 'Items', 'Total (INR)'];
  const ordersRows = (orders) => [ORDER_HEAD, ...orders.map((o) => {
    const d = new Date(o.created_at);
    return [o.order_no, ymd(d), hm(d), locName(o.location_id), o.status, o.customer_name, o.customer_phone, o.alt_phone, o.address, o.landmark, o.pincode, o.notes, itemsText(o), Number(o.total)];
  })];
  const LINE_HEAD = ['Order no', 'Date', 'Location', 'Status', 'Customer', 'Product', 'Category', 'Pack', 'Qty', 'Unit price (INR)', 'Line total (INR)'];
  const linesRows = (orders) => [LINE_HEAD, ...orders.flatMap((o) => (o.items || []).map((i) => [
    o.order_no, ymd(new Date(o.created_at)), locName(o.location_id), o.status, o.customer_name, i.name_en, categoryOf(i.product_id), i.pack_label, i.quantity, Number(i.unit_price), Number(i.line_total)]))];

  function saveBlob(blob, filename) {
    const a = el('a', { href: URL.createObjectURL(blob), download: filename });
    document.body.append(a); a.click(); a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 4000);
  }
  const csvText = (rows) => '﻿' + rows.map((r) => r.map((v) => '"' + String(v ?? '').replace(/"/g, '""') + '"').join(',')).join('\r\n');
  const downloadCsv = (filename, rows) => saveBlob(new Blob([csvText(rows)], { type: 'text/csv;charset=utf-8' }), filename);
  function downloadXlsx(filename, sheets) {
    if (!window.XLSX) return toast('Excel export could not load. Use the CSV buttons instead.', true);
    const wb = window.XLSX.utils.book_new();
    for (const s of sheets) window.XLSX.utils.book_append_sheet(wb, window.XLSX.utils.aoa_to_sheet(s.rows), s.name.slice(0, 31));
    window.XLSX.writeFile(wb, filename);
  }
  async function busy(btn, fn) {
    const label = btn.textContent;
    btn.disabled = true; btn.textContent = 'Preparing…';
    try { await fn(); } catch (e) { toast('Could not prepare the report: ' + (e.message || e), true); }
    btn.disabled = false; btn.textContent = label;
  }

  // ---------------------------------------------------------------- ORDERS (table, filters, 20 per page)
  async function renderOrders(root) {
    const f = S.of;
    const q = el('input', { class: 'search-in', type: 'search', placeholder: 'Search order no, name or phone', value: f.q });
    const dates = dateControls(f, () => { f.page = 1; load(); });
    const locSel = S.locations.length > 1
      ? el('select', { class: 'field slim', 'aria-label': 'Location', onchange: (e) => { f.loc = e.target.value; f.page = 1; load(); } },
          el('option', { value: '' }, 'All locations'), ...S.locations.map((l) => el('option', { value: l.id, selected: f.loc === l.id }, l.name_en)))
      : null;
    const seg = el('div', { class: 'seg' });
    const host = el('div', { class: 'listcard otable' + (S.locations.length > 1 ? '' : ' noloc') });
    const pager = el('div', { class: 'pager' });
    const dl = el('button', { class: 'btn', onclick: (e) => busy(e.currentTarget, async () => {
      const rows = await fetchAllOrders(f, f.status);
      if (!rows.length) return toast('No orders match these filters.');
      downloadCsv(`orders-${ymd(new Date())}.csv`, ordersRows(rows)); toast(`${rows.length} orders downloaded`);
    }) }, ico('download', 16), 'Download CSV');
    root.append(
      pageHead('Orders', 'Click an order to see its details. New orders appear automatically.', el('button', { class: 'btn', onclick: () => load() }, ico('refresh', 16), 'Refresh'), dl),
      el('div', { class: 'card filters' }, el('label', { class: 'searchbox grow' }, ico('search', 16), q), dates, locSel),
      seg, host, pager);

    let timer;
    q.addEventListener('input', () => { clearTimeout(timer); timer = setTimeout(() => { f.q = q.value; f.page = 1; load(); }, 400); });
    S.reloadOrders = load;

    async function load() {
      host.replaceChildren(el('div', { class: 'skel', style: 'height:300px;border-radius:0' }));
      const from = (f.page - 1) * PAGE_SIZE;
      const [res, ...cnt] = await Promise.all([
        ordersQuery(f, f.status, '*,items:order_items(*)', { count: 'exact' }).order('created_at', { ascending: false }).range(from, from + PAGE_SIZE - 1),
        ...STATUS_KEYS.map((s) => ordersQuery(f, s, 'id', { count: 'exact', head: true })),
      ]);
      if (S.view !== 'orders') return;
      if (res.error) { host.replaceChildren(emptyState('alert', 'Could not load orders. Has the orders SQL (0005_orders.sql) been run?')); return; }
      const counts = Object.fromEntries(STATUS_KEYS.map((s, i) => [s, cnt[i].count || 0]));
      counts.all = STATUS_KEYS.reduce((n, s) => n + counts[s], 0);
      const total = res.count || 0, pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
      if (f.page > pages) { f.page = pages; return load(); }
      setBadge(counts.new && !f.loc && f.range === 'all' && !f.q ? counts.new : S.newCount);

      seg.replaceChildren(...[['all', 'All'], ['new', 'New'], ['confirmed', 'Confirmed'], ['delivered', 'Delivered'], ['cancelled', 'Cancelled']].map(([v, t]) =>
        el('button', { class: f.status === v ? 'on' : '', onclick: () => { f.status = v; f.page = 1; load(); } }, t, el('span', { class: 'cnt' }, String(counts[v])))));

      host.replaceChildren();
      if (!res.data.length) {
        host.append(emptyState('inbox', 'No orders match these filters.'));
      } else {
        host.append(el('div', { class: 'ohead orow' }, ['Order', 'Placed', 'Location', 'Customer', 'Items', 'Total', 'Status', ''].map((t, i) => el('span', { class: 'c-' + ['no', 'date', 'loc', 'cust', 'items', 'total', 'status', 'act'][i] }, t))));
        res.data.forEach((o) => host.append(orderRow(o)));
      }
      const first = total ? from + 1 : 0, last = Math.min(total, from + PAGE_SIZE);
      const go = (p) => { f.page = p; load(); window.scrollTo({ top: 0, behavior: 'smooth' }); };
      pager.replaceChildren(
        el('span', { class: 'muted' }, total ? `Showing ${first}–${last} of ${total}` : 'No results'),
        el('span', { class: 'pgbtns' },
          el('button', { class: 'btn small', disabled: f.page <= 1, onclick: () => go(1), 'aria-label': 'First page' }, '«'),
          el('button', { class: 'btn small', disabled: f.page <= 1, onclick: () => go(f.page - 1) }, '‹ Prev'),
          el('span', { class: 'pgnum' }, `Page ${f.page} of ${pages}`),
          el('button', { class: 'btn small', disabled: f.page >= pages, onclick: () => go(f.page + 1) }, 'Next ›'),
          el('button', { class: 'btn small', disabled: f.page >= pages, onclick: () => go(pages), 'aria-label': 'Last page' }, '»')));
    }
    load();
  }

  function orderRow(o) {
    const [stText, stCls] = ORDER_STATUS[o.status] || [o.status, ''];
    const items = o.items || [];
    const shown = items.slice(0, 2).map((i) => `${i.quantity}× ${i.name_en} (${i.pack_label})`).join(', ');
    const more = items.length > 2 ? ` +${items.length - 2} more` : '';
    return el('div', { class: 'orow' + (o.status === 'new' ? ' isnew' : ''), tabindex: '0', role: 'button', onclick: () => openOrder(o), onkeydown: (e) => { if (e.key === 'Enter') openOrder(o); } },
      el('span', { class: 'c-no' }, '#' + o.order_no),
      el('span', { class: 'c-date' }, when(o.created_at), el('span', { class: 'loc-inline' }, ' · ' + locName(o.location_id))),
      el('span', { class: 'c-loc' }, locName(o.location_id)),
      el('span', { class: 'c-cust' }, el('b', null, o.customer_name), el('small', null, o.customer_phone)),
      el('span', { class: 'c-items' }, shown + more),
      el('span', { class: 'c-total' }, inr(o.total)),
      el('span', { class: 'c-status' }, el('span', { class: 'pill ' + stCls }, stText)),
      el('span', { class: 'c-act' }, o.status === 'new'
        ? el('button', { class: 'btn small primary', onclick: (e) => { e.stopPropagation(); setOrderStatus(o, 'confirmed'); } }, 'Confirm')
        : el('span', { class: 'muted' }, '›')));
  }
  const openOrder = (o) => openSheet('Order #' + o.order_no, () => [orderCard(o)]);

  // ---------------------------------------------------------------- REPORTS
  const REPORT_MODES = { cd: ['Confirmed + delivered orders', ['confirmed', 'delivered']], ex: ['All except cancelled', ['new', 'confirmed', 'delivered']], d: ['Delivered only', ['delivered']] };

  async function renderReports(root) {
    const f = S.rp;
    const owner = isOwner();
    const results = el('div');
    const downloads = el('div');
    const dates = dateControls(f, () => load());
    const locSel = S.locations.length > 1
      ? el('select', { class: 'field slim', 'aria-label': 'Location', onchange: (e) => { f.loc = e.target.value; load(); } },
          el('option', { value: '' }, owner ? 'All locations' : 'All my locations'), ...S.locations.map((l) => el('option', { value: l.id, selected: f.loc === l.id }, l.name_en)))
      : null;
    const modeSel = el('select', { class: 'field slim', 'aria-label': 'Orders to count', onchange: (e) => { f.mode = e.target.value; load(); } },
      Object.entries(REPORT_MODES).map(([k, [t]]) => el('option', { value: k, selected: f.mode === k }, t)));
    root.append(
      pageHead('Reports', owner ? 'Sales for every location. Download any report, or everything in one Excel file.' : `Sales for ${S.locations.map((l) => l.name_en).join(', ')}.`),
      el('div', { class: 'card filters' }, dates, locSel, modeSel), results, downloads);

    async function load() {
      results.replaceChildren(skeleton(2, 120));
      downloads.replaceChildren();
      const r = rangeFor(f.range, f.from, f.to);
      const from = r ? r.from : new Date(2000, 0, 1), to = r ? r.to : new Date(Date.now() + 86400000);
      const { data, error } = await sb.rpc('sales_report', { p_from: from.toISOString(), p_to: to.toISOString(), p_location: f.loc || null, p_statuses: REPORT_MODES[f.mode][1] });
      if (S.view !== 'reports') return;
      if (error) { results.replaceChildren(emptyState('alert', 'Could not build the report. Has 0006_sales_report.sql been run? (' + error.message + ')')); return; }
      draw(data, from, to);
    }

    function table(head, rows, right = []) {
      return el('div', { class: 'tscroll' }, el('table', { class: 'rtable' },
        el('thead', null, el('tr', null, head.map((h, i) => el('th', { class: right.includes(i) ? 'r' : '' }, h)))),
        el('tbody', null, rows.map((r) => el('tr', null, r.map((c, i) => el('td', { class: right.includes(i) ? 'r' : '' }, c)))))));
    }
    const section = (title, ...kids) => el('div', { class: 'card', style: 'margin-bottom:14px' }, el('h3', { style: 'margin-bottom:10px' }, title), ...kids);

    function draw(d, from, to) {
      const s = d.summary;
      const kpi = (label, value) => el('div', { class: 'kpi' }, el('small', null, label), el('b', null, value));
      const days = d.by_day || [], maxSales = Math.max(1, ...days.map((x) => Number(x.sales)));
      const shownDays = days.slice(-31).reverse();
      results.replaceChildren(
        el('div', { class: 'kpis' }, kpi('Total sales', inr(s.sales)), kpi('Orders', String(s.orders)), kpi('Average order', inr(s.avg_order)), kpi('Items sold', String(s.items))),
        ...(!s.orders ? [emptyState('inbox', 'No orders in this period.')] : [
          section('Sales by day', table(['Date', 'Orders', 'Sales', ''], shownDays.map((x) => [
            new Date(x.day + 'T00:00:00').toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }), String(x.orders), inr(x.sales),
            el('div', { class: 'bar', style: 'min-width:80px;margin:0' }, el('i', { style: `width:${Math.round((Number(x.sales) / maxSales) * 100)}%` }))]), [1, 2]),
            days.length > 31 ? el('p', { class: 'hint' }, `Showing the latest 31 days. Download the report for all ${days.length} days.`) : null),
          owner && (d.by_location || []).length > 1 ? section('Sales by location', table(['Location', 'Orders', 'Sales'], d.by_location.map((x) => [x.location, String(x.orders), inr(x.sales)]), [1, 2])) : null,
          section('Top products', table(['Product', 'Category', 'Qty', 'Sales'], (d.products || []).slice(0, 15).map((x) => [x.product, x.category, String(x.qty), inr(x.revenue)]), [2, 3]),
            (d.products || []).length > 15 ? el('p', { class: 'hint' }, 'Top 15 shown. Download the product report for the full list.') : null),
          section('Sales by category', table(['Category', 'Qty', 'Sales'], (d.categories || []).map((x) => [x.category, String(x.qty), inr(x.revenue)]), [1, 2])),
        ]).filter(Boolean));

      // ---- downloads
      const tag = `${ymd(from) > '2001' ? ymd(from) : 'start'}_to_${ymd(new Date(to.getTime() - 86400000))}${f.loc ? '-' + (S.locations.find((l) => l.id === f.loc) || {}).slug : ''}`;
      const sheetDay = [['Date', 'Orders', 'Sales (INR)'], ...days.map((x) => [x.day, Number(x.orders), Number(x.sales)])];
      const sheetLoc = [['Location', 'Orders', 'Sales (INR)'], ...(d.by_location || []).map((x) => [x.location, Number(x.orders), Number(x.sales)])];
      const sheetProd = [['Product', 'Category', 'Qty', 'Sales (INR)'], ...(d.products || []).map((x) => [x.product, x.category, Number(x.qty), Number(x.revenue)])];
      const sheetCat = [['Category', 'Qty', 'Sales (INR)'], ...(d.categories || []).map((x) => [x.category, Number(x.qty), Number(x.revenue)])];
      const sheetSum = [['Report', owner ? 'All reports' : 'Location reports'], ['Period', `${ymd(from) > '2001' ? ymd(from) : 'All time'} to ${ymd(new Date(to.getTime() - 86400000))}`],
        ['Location', f.loc ? locName(f.loc) : (owner ? 'All locations' : S.locations.map((l) => l.name_en).join(', '))], ['Orders counted', REPORT_MODES[f.mode][0]], [],
        ['Total sales (INR)', Number(s.sales)], ['Orders', Number(s.orders)], ['Average order (INR)', Number(s.avg_order)], ['Items sold', Number(s.items)]];
      const fullOrders = async () => fetchAllOrders({ loc: f.loc, range: f.range, from: f.from, to: f.to, q: '' }, REPORT_MODES[f.mode][1]);
      const csvBtn = (label, name, rows) => el('button', { class: 'btn small', onclick: () => { downloadCsv(`${name}-${tag}.csv`, rows); } }, ico('download', 14), label);
      const asyncBtn = (label, name, build) => el('button', { class: 'btn small', onclick: (e) => busy(e.currentTarget, async () => {
        const orders = await fullOrders();
        if (!orders.length) return toast('No orders in this period.');
        downloadCsv(`${name}-${tag}.csv`, build(orders));
      }) }, ico('download', 14), label);
      downloads.replaceChildren(el('div', { class: 'card' },
        el('h3', null, owner ? 'Download reports (all locations)' : 'Download reports for your location'),
        el('p', { class: 'hint' }, 'CSV files open in Excel or Google Sheets. The Excel file puts every report on its own sheet.'),
        el('div', { class: 'acts' },
          el('button', { class: 'btn primary', onclick: (e) => busy(e.currentTarget, async () => {
            const orders = await fullOrders();
            downloadXlsx(`am-vegetables-${owner ? 'all-reports' : 'location-report'}-${tag}.xlsx`, [
              { name: 'Summary', rows: sheetSum }, { name: 'Sales by day', rows: sheetDay },
              ...(owner ? [{ name: 'Sales by location', rows: sheetLoc }] : []),
              { name: 'Products', rows: sheetProd }, { name: 'Categories', rows: sheetCat },
              { name: 'Orders', rows: ordersRows(orders) }, { name: 'Order items', rows: linesRows(orders) }]);
          }) }, ico('download', 16), owner ? 'Excel: all reports' : 'Excel: my reports'),
          csvBtn('Sales by day', 'sales-by-day', sheetDay),
          owner ? csvBtn('Sales by location', 'sales-by-location', sheetLoc) : null,
          csvBtn('Product sales', 'product-sales', sheetProd),
          csvBtn('Category sales', 'category-sales', sheetCat),
          asyncBtn('Orders', 'orders', ordersRows),
          asyncBtn('Order items', 'order-items', linesRows))));
    }
    load();
  }

  async function renderLocations(root) {
    if (!isOwner()) return;
    const head = () => pageHead('Locations', 'Each location has its own address, WhatsApp number, prices and team.',
      el('button', { class: 'btn primary', onclick: () => openLocation(null, () => render()) }, ico('plus', 16), 'Add location'));
    root.append(head(), skeleton(3, 260));
    let settings, vendors, vls, ownerCfg, counts;
    try {
      [settings, vendors, vls, ownerCfg] = await Promise.all([
        run(sb.from('location_settings').select('*'), 'Load shops'),
        run(sb.from('profiles').select('user_id,name,email,phone').eq('role', 'vendor'), 'Load team'),
        run(sb.from('vendor_locations').select('user_id,location_id'), 'Load team'),
        run(sb.from('app_settings').select('value').eq('key', 'owner_notify').maybeSingle(), 'Load owner settings'),
      ]);
      counts = await Promise.all(S.locations.map(async (l) => {
        const sellN = await sb.from('location_products').select('product_id', { count: 'exact', head: true }).eq('location_id', l.id).eq('is_available', true);
        const priced = await sb.from('location_pack_prices').select('pack_id', { count: 'exact', head: true }).eq('location_id', l.id).not('price', 'is', null);
        return { id: l.id, selling: sellN.count || 0, priced: priced.count || 0 };
      }));
    } catch (_) { root.replaceChildren(head(), emptyState('alert', 'Could not load. Check the message shown.')); return; }
    if (S.view !== 'locations') return;
    const setBy = new Map(settings.map((s) => [s.location_id, s]));
    const cnt = new Map(counts.map((c) => [c.id, c]));
    const vendorBy = new Map(vendors.map((v) => [v.user_id, v]));

    const ownerWa = el('input', { class: 'field', inputmode: 'tel', value: showPhone(ownerCfg && ownerCfg.value && ownerCfg.value.whatsapp), placeholder: '10-digit mobile number' });
    const ownerCard = el('div', { class: 'card', style: 'margin-bottom:14px' },
      el('div', { class: 'person' }, el('div', { class: 'avatar' }, ico('chat', 18)),
        el('div', null, el('h3', null, 'Owner copy of orders'), el('div', { class: 'hint', style: 'margin:0' }, 'Orders go to each location’s own WhatsApp number. Your number is where a copy for you will be sent.'))),
      el('div', { class: 'acts', style: 'align-items:center' },
        el('div', { style: 'flex:1 1 220px' }, ownerWa),
        el('button', { class: 'btn', onclick: async () => {
          const wa = normPhone(ownerWa.value);
          if (wa && wa.length !== 12) return toast('Enter a 10-digit mobile number.', true);
          await run(sb.from('app_settings').upsert({ key: 'owner_notify', value: { whatsapp: wa } }, { onConflict: 'key' }), 'Save');
          toast('Saved');
        } }, 'Save my number')));

    const grid = el('div', { class: 'cards' });
    for (const l of S.locations) {
      const s = setBy.get(l.id) || {}, c = cnt.get(l.id) || {};
      const team = vls.filter((v) => v.location_id === l.id).map((v) => { const u = vendorBy.get(v.user_id) || {}; return u.name || showPhone(u.phone); }).filter(Boolean);
      grid.append(el('div', { class: 'card' },
        el('div', { class: 'lhead' },
          el('div', null, el('h3', null, l.name_en), el('div', { class: 'pta ta' }, l.name_ta)),
          tog('Live in app', l.is_active, async (v, i) => {
            const { error } = await sb.from('locations').update({ is_active: v }).eq('id', l.id);
            if (error) { toast(error.message, true); i.checked = !v; return; }
            l.is_active = v; buildChrome();
          })),
        el('div', { class: 'pills' },
          s.is_open === false ? el('span', { class: 'pill off' }, 'Closed') : el('span', { class: 'pill ok' }, 'Open'),
          !s.whatsapp ? el('span', { class: 'pill warn' }, 'No WhatsApp number') : null,
          !s.address ? el('span', { class: 'pill warn' }, 'No address') : null),
        kv('pin', s.address || 'Address not set', !s.address),
        kv('chat', s.whatsapp ? showPhone(s.whatsapp) : 'WhatsApp number not set', !s.whatsapp),
        deliveryLine(s),
        kv('clock', s.hours || 'Opening hours not set', !s.hours),
        kv('users', team.length ? team.join(', ') : 'No vendors yet'),
        el('div', { class: 'stats' }, stat(c.selling || 0, 'products selling'), stat(c.priced || 0, 'prices set')),
        el('div', { class: 'acts' },
          el('button', { class: 'btn small primary', onclick: () => openLocation(l, () => render()) }, ico('pencil', 14), 'Edit details'),
          el('button', { class: 'btn small', onclick: () => { S.locId = l.id; S.view = 'products'; try { localStorage.setItem('am-loc', l.id); } catch (_) {} buildChrome(); loadLocation(); } }, ico('leaf', 14), 'Open products'))));
    }
    root.replaceChildren(head(), ownerCard, grid);
  }

  async function renderMyShop(root) {
    root.append(pageHead('My shop', loc().name_en), skeleton(1, 260));
    let s;
    try { s = await run(sb.from('location_settings').select('*').eq('location_id', S.locId).maybeSingle(), 'Load shop'); } catch (_) { return; }
    if (S.view !== 'shop') return;
    s = s || {};
    root.replaceChildren(
      pageHead('My shop', 'These details are shown to customers who pick your location.',
        el('button', { class: 'btn primary', onclick: () => openLocation(loc(), () => render()) }, ico('pencil', 16), 'Edit shop details')),
      el('div', { class: 'card', style: 'max-width:560px' },
        el('h3', null, loc().name_en),
        el('div', { class: 'pills' }, s.is_open === false ? el('span', { class: 'pill off' }, 'Closed') : el('span', { class: 'pill ok' }, 'Open'),
          !s.whatsapp ? el('span', { class: 'pill warn' }, 'No WhatsApp number') : null),
        kv('pin', s.address || 'Address not set', !s.address),
        kv('chat', s.whatsapp ? 'Orders go to ' + showPhone(s.whatsapp) : 'WhatsApp number not set. Orders have nowhere to go.', !s.whatsapp),
        deliveryLine(s),
        kv('clock', s.hours || 'Opening hours not set', !s.hours),
        s.phone ? kv('chat', 'Call: ' + s.phone) : null));
  }


  async function openLocation(l, done) {
    const owner = isOwner();
    let s = {};
    if (l) { try { s = (await run(sb.from('location_settings').select('*').eq('location_id', l.id).maybeSingle(), 'Load shop')) || {}; } catch (_) { return; } }
    const b = s.banner || {};
    let pins = (s.pincodes || []).map((x) => ({ ...x }));
    let open = s.is_open !== false, live = l ? l.is_active : true;
    const f = (v, a) => el('input', { class: 'field', value: v || '', ...(a || {}) });
    const fn = f(l && l.name_en, { placeholder: 'e.g. Rajapalayam', disabled: !owner });
    const ft = f(l && l.name_ta, { class: 'field ta', placeholder: 'தமிழ் பெயர்', disabled: !owner });
    const addr = el('textarea', { class: 'field', value: s.address || '', placeholder: 'Shop address (door no, street, area, city, pincode)' });
    const maps = f(s.maps_url, { placeholder: 'Google Maps link (optional)' });
    const wa = f(showPhone(s.whatsapp), { inputmode: 'tel', placeholder: '10-digit WhatsApp number' });
    const ph = f(s.phone, { inputmode: 'tel', placeholder: 'Call number (optional)' });
    const hrs = f(s.hours, { placeholder: 'e.g. 6:00 AM – 9:00 PM' });
    const pay = f(s.payment_note);
    const bt = f(b.title_en), btt = f(b.title_ta, { class: 'field ta' }), chip = f(b.chip), body = el('textarea', { class: 'field', value: b.body || '' });
    const copy = el('input', { type: 'checkbox' });
    const pinBox = el('div');
    const drawPins = () => pinBox.replaceChildren(...pins.map((x, i) => el('div', { class: 'prow' },
      el('input', { class: 'field pin', inputmode: 'numeric', maxlength: '6', value: x.pincode || '', placeholder: 'Pincode', oninput: (e) => { x.pincode = e.target.value; } }),
      el('input', { class: 'field area', value: x.area || '', placeholder: 'Area', oninput: (e) => { x.area = e.target.value; } }),
      sw(x.active !== false, (v) => { x.active = v; }),
      el('button', { class: 'btn small danger', onclick: () => { pins.splice(i, 1); drawPins(); } }, '✕'))));
    drawPins();

    openSheet(l ? (owner ? 'Edit location' : 'Shop details') : 'Add location', (close) => [
      sec('Location',
        lbl('Name', 'English'), fn, lbl('Name', 'தமிழ்'), ft,
        owner ? el('div', { class: 'row', style: 'margin-top:12px' }, el('span', null, el('b', null, 'Live in the app'), el('div', { class: 'hint' }, 'Customers can pick this location')), sw(live, (v) => { live = v; })) : null,
        el('div', { class: 'row', style: 'margin-top:12px' }, el('span', null, el('b', null, 'Shop open now')), sw(open, (v) => { open = v; }))),
      sec('Address & orders',
        lbl('Address', 'முகவரி'), addr, lbl('Map link'), maps,
        lbl('WhatsApp number for orders', null, 'orders from this location go here'), wa,
        lbl('Call number'), ph, lbl('Opening hours'), hrs),
      sec('Delivery pincodes', el('p', { class: 'hint' }, 'Orders to any other pincode are refused. Leave this empty to accept every pincode.'), pinBox,
        el('button', { class: 'btn small', onclick: () => { pins.push({ pincode: '', area: '', active: true }); drawPins(); } }, '＋ Add pincode')),
      el('div', { class: 'sec' }, el('details', null, el('summary', null, 'Banner & payment note (optional)'),
        lbl('Payment note'), pay, lbl('Banner title (English)'), bt, lbl('Banner title (Tamil)'), btt, lbl('Banner chip'), chip, lbl('Banner text'), body)),
      !l && owner ? el('label', { class: 'sec', style: 'display:flex;gap:10px;align-items:center;padding:14px' }, copy, el('span', null, `Also copy the product list of ${loc().name_en} (no prices)`)) : null,
      el('div', { class: 'sheetfoot' }, el('button', { class: 'btn primary', onclick: async (e) => {
        const name = fn.value.trim();
        if (!l && !name) return toast('Enter the location name.', true);
        const waN = normPhone(wa.value);
        if (waN && waN.length !== 12) return toast('WhatsApp number must be 10 digits.', true);
        const clean = pins.filter((x) => (x.pincode || '').trim()).map((x) => ({ pincode: x.pincode.trim(), area: (x.area || '').trim(), active: x.active !== false }));
        if (clean.some((x) => !/^\d{6}$/.test(x.pincode))) return toast('Pincodes must be 6 digits.', true);
        e.target.disabled = true;
        try {
          let id = l && l.id;
          if (!l) {
            const [c] = await run(sb.from('locations').insert({ slug: slugify(name), name_en: name, name_ta: ft.value.trim(), is_active: live, sort: S.locations.length + 1 }).select(), 'Create location');
            id = c.id; S.locations.push(c);
          } else if (owner) {
            await run(sb.from('locations').update({ name_en: fn.value.trim() || l.name_en, name_ta: ft.value.trim(), is_active: live }).eq('id', id), 'Save location');
            Object.assign(l, { name_en: fn.value.trim() || l.name_en, name_ta: ft.value.trim(), is_active: live });
          }
          await run(sb.from('location_settings').upsert({
            location_id: id, address: addr.value.trim(), maps_url: maps.value.trim(), whatsapp: waN, phone: ph.value.trim(), hours: hrs.value.trim(),
            is_open: open, payment_note: pay.value.trim(), pincodes: clean,
            banner: { ...b, title_en: bt.value.trim(), title_ta: btt.value.trim(), chip: chip.value.trim(), body: body.value.trim() },
          }, { onConflict: 'location_id' }), 'Save shop');
          if (!l && copy.checked) {
            const rows = [...S.lp.values()].filter((r) => r.is_available).map((r) => ({ location_id: id, product_id: r.product_id, is_available: true, in_stock: true, featured: r.featured }));
            await upsertAll('location_products', rows, 'location_id,product_id', 'Copy products');
          }
          close(); buildChrome(); toast('Saved ✓'); done && done();
        } catch (_) { e.target.disabled = false; }
      } }, 'Save')),
    ], { sticky: true });
  }

  // ------------------------------------------------------------------ TEAM (owner)
  async function renderTeam(root) {
    if (!isOwner()) return;
    const head = () => pageHead('Team', 'Vendors manage stock, prices and shop details for their own locations only.',
      el('button', { class: 'btn primary', onclick: () => vendorSheet(null, []) }, ico('plus', 16), 'Add vendor'));
    root.append(head(), skeleton(2, 150));
    let vendors, vls;
    try {
      [vendors, vls] = await Promise.all([
        run(sb.from('profiles').select('user_id,name,email,phone').eq('role', 'vendor').order('name'), 'Load team'),
        run(sb.from('vendor_locations').select('user_id,location_id'), 'Load team'),
      ]);
    } catch (_) { return; }
    if (S.view !== 'team') return;
    const grid = el('div', { class: 'cards' });
    for (const v of vendors) {
      const ids = vls.filter((x) => x.user_id === v.user_id).map((x) => x.location_id);
      const mine = ids.map((id) => (S.locations.find((l) => l.id === id) || {}).name_en).filter(Boolean);
      grid.append(el('div', { class: 'card' },
        el('div', { class: 'person' },
          el('div', { class: 'avatar' }, (v.name || showPhone(v.phone) || '?').trim().charAt(0).toUpperCase()),
          el('div', { style: 'min-width:0' }, el('h3', null, v.name || showPhone(v.phone)), el('div', { class: 'hint', style: 'margin:0' }, showPhone(v.phone) || v.email))),
        el('div', { class: 'pills' }, ...(mine.length ? mine.map((n) => el('span', { class: 'pill ok' }, n)) : [el('span', { class: 'pill warn' }, 'No location')])),
        el('div', { class: 'acts' }, el('button', { class: 'btn small', onclick: () => vendorSheet(v, ids) }, ico('pencil', 14), 'Edit / reset password'))));
    }
    root.replaceChildren(head(), vendors.length ? grid : emptyState('users', 'No vendors yet. Add one so a shop can manage its own prices.'));
  }

  function genPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    const buf = new Uint32Array(10); crypto.getRandomValues(buf);
    return [...buf].map((n) => chars[n % chars.length]).join('');
  }

  async function saveVendor(payload) {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) throw new Error('Please log in again.');
    let r, j = {};
    try {
      r = await fetch('/api/admin/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + session.access_token },
        body: JSON.stringify(payload),
      });
      j = await r.json();
    } catch (_) {
      throw new Error('Cannot reach the server. Start the panel with "npm run dev:admin" (or use the deployed site).');
    }
    if (!r.ok) throw new Error(j.error || 'Could not save the vendor.');
    return j;
  }

  function loginDetailsSheet(phone, password, created) {
    const text = 'AM Vegetables admin\nLogin: ' + location.origin + '/staff\nMobile number: ' + showPhone(phone) + '\nPassword: ' + password;
    openSheet(created ? 'Vendor created ✓' : 'Password changed ✓', () => [
      sec(null,
        el('p', { class: 'hint', style: 'margin-top:12px' }, 'Share these login details with the vendor now. The password is not shown again.'),
        el('div', { class: 'kv' }, el('b', null, 'Mobile'), el('span', null, showPhone(phone))),
        el('div', { class: 'kv' }, el('b', null, 'Password'), el('span', { style: 'font-family:monospace;font-weight:800;font-size:17px' }, password)),
        el('div', { class: 'acts' },
          el('button', { class: 'btn primary', onclick: async () => {
            try { await navigator.clipboard.writeText(text); toast('Copied ✓'); } catch (_) { toast('Copy failed, select the text instead.', true); }
          } }, 'Copy'),
          el('a', { class: 'btn', style: 'text-decoration:none', href: 'https://wa.me/' + phone + '?text=' + encodeURIComponent(text), target: '_blank', rel: 'noopener' }, 'Send on WhatsApp'))),
    ], { sticky: true });
  }

  function vendorSheet(v, current) {
    const phone = el('input', { class: 'field', type: 'tel', inputmode: 'tel', value: v ? showPhone(v.phone) : '', placeholder: '10-digit mobile number', disabled: !!v, autocomplete: 'off' });
    const name = el('input', { class: 'field', value: v ? v.name : '', placeholder: 'Vendor name' });
    const pw = el('input', { class: 'field', type: 'text', value: '', autocomplete: 'new-password', placeholder: v ? 'Leave blank to keep current password' : 'At least 8 characters' });
    if (!v) pw.value = genPassword();
    const chosen = new Set(current);
    const boxes = el('div', { class: 'sellrow' }, S.locations.map((l) => {
      const i = el('input', { type: 'checkbox', checked: chosen.has(l.id) });
      i.addEventListener('change', () => (i.checked ? chosen.add(l.id) : chosen.delete(l.id)));
      return el('label', null, i, l.name_en);
    }));
    openSheet(v ? 'Edit vendor' : 'Add vendor', (close) => [
      sec(null,
        lbl('Mobile number', null, 'they log in with this'), phone,
        lbl('Name'), name,
        lbl(v ? 'New password' : 'Password', null, v ? 'only to reset it' : 'you can change it'), pw,
        el('div', { class: 'acts', style: 'margin-top:8px' }, el('button', { class: 'btn small', onclick: () => { pw.value = genPassword(); } }, ico('refresh', 16), 'Generate')),
        lbl('Locations they manage'), boxes),
      el('div', { class: 'sheetfoot' },
        v ? el('button', { class: 'btn danger', onclick: async () => {
          if (!confirm('Remove ' + (v.name || showPhone(v.phone)) + "'s access?")) return;
          await run(sb.rpc('owner_remove_vendor', { p_user: v.user_id }), 'Remove vendor');
          close(); render(); toast('Access removed');
        } }, 'Remove') : null,
        el('button', { class: 'btn primary', onclick: async (e) => {
          const pass = pw.value.trim();
          const ph = v ? v.phone : normPhone(phone.value);
          if (ph.length !== 12) return toast('Enter a 10-digit mobile number.', true);
          if (!chosen.size) return toast('Choose at least one location.', true);
          if (!v && !pass) return toast('Set a password for the vendor.', true);
          if (pass && pass.length < 8) return toast('Password must be at least 8 characters.', true);
          e.target.disabled = true;
          try {
            const out = await saveVendor({ phone: ph, name: name.value.trim(), password: pass, locations: [...chosen] });
            close(); render();
            if (pass) loginDetailsSheet(ph, pass, out.created); else toast('Saved ✓');
          } catch (err) { toast(err.message, true); e.target.disabled = false; }
        } }, 'Save')),
    ], { sticky: true });
  }

  start().catch((e) => showLogin(e.message));
  sb.auth.onAuthStateChange((ev) => { if (ev === 'SIGNED_OUT') showLogin(); });
})();
