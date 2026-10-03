/* Extras for the Decap CMS: live product-card preview + link to the Stock page.
   Loaded from admin/index.html after decap-cms.js. */
(function () {
  if (!window.CMS) return;
  var h = window.h; // Decap's React.createElement shorthand

  // ---------- Live preview: the product card as customers see it in the app ----------
  var css = [
    '.am{font-family:"Plus Jakarta Sans","Noto Sans Tamil",system-ui,sans-serif;background:#f3f8f2;padding:20px;min-height:100%}',
    '.am .card{width:270px;margin:0 auto;background:#fff;border-radius:28px;padding:8px;box-shadow:0 10px 18px rgba(0,0,0,.09)}',
    '.am .img{position:relative;border-radius:22px;overflow:hidden;aspect-ratio:1.05;background:#dfe8dc}',
    '.am .img img{width:100%;height:100%;object-fit:cover;display:block}',
    '.am .out .img img{filter:grayscale(1)}',
    '.am .shade{position:absolute;left:0;right:0;bottom:0;height:58px;background:linear-gradient(transparent,rgba(0,0,0,.5))}',
    '.am .origin{position:absolute;left:10px;right:10px;bottom:8px;color:#fff;font-size:10.5px;font-weight:700}',
    '.am .badge{position:absolute;left:8px;top:8px;background:#fff;border-radius:12px;padding:4px 9px;font-size:11px;font-weight:700;color:#0b6b3a}',
    '.am .soldout{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.35);color:#fff;font-weight:700}',
    '.am .body{padding:10px 8px 6px}',
    '.am .en{font-size:15px;font-weight:700;color:#1b2b22;margin:0}',
    '.am .ta{font-size:12.5px;color:#6b7c72;margin:2px 0 0}',
    '.am .tag{font-size:12px;color:#0b6b3a;margin:6px 0 0;font-weight:600}',
    '.am .packs{display:flex;flex-wrap:wrap;gap:6px;margin-top:10px}',
    '.am .pack{border:1.5px solid #d8f5df;border-radius:14px;padding:4px 10px;font-size:12px;font-weight:600;color:#1b2b22}',
    '.am .pack.def{background:#0b6b3a;border-color:#0b6b3a;color:#fff}',
    '.am .pack small{color:#f5a623;margin-left:4px}',
    '.am .note{text-align:center;color:#6b7c72;font-size:11px;margin-top:12px}'
  ].join('');
  CMS.registerPreviewStyle(css, { raw: true });

  function plain(v) { return v && v.toJS ? v.toJS() : v; }

  var ProductPreview = function (props) {
    var e = props.entry;
    var get = function (k) { return e.getIn(['data', k]); };
    var img = get('image');
    var src = img ? String(props.getAsset(img) || img) : '';
    var out = get('in_stock') === false;
    var packs = plain(get('packs')) || [];

    return h('div', { className: 'am' },
      h('div', { className: 'card' + (out ? ' out' : '') },
        h('div', { className: 'img' },
          src ? h('img', { src: src, alt: '' }) : null,
          h('div', { className: 'shade' }),
          get('origin') ? h('div', { className: 'origin' }, '📍 ' + get('origin')) : null,
          get('badge') && !out ? h('div', { className: 'badge' }, get('badge')) : null,
          out ? h('div', { className: 'soldout' }, 'Out of stock') : null
        ),
        h('div', { className: 'body' },
          h('p', { className: 'en' }, get('name_en') || 'Product name'),
          h('p', { className: 'ta' }, get('name_ta') || ''),
          get('tagline') ? h('p', { className: 'tag' }, get('tagline')) : null,
          h('div', { className: 'packs' }, packs.map(function (p, i) {
            return h('span', { key: i, className: 'pack' + (p.is_default ? ' def' : '') },
              p.label_en || '',
              p.popular ? h('small', null, '★') : null);
          }))
        )
      ),
      h('div', { className: 'note' }, 'Approximate card as shown in the app')
    );
  };
  CMS.registerPreviewTemplate('products', ProductPreview);

  // ---------- Link to the bulk Stock page (Decap has no slot for custom nav) ----------
  var a = document.createElement('a');
  a.href = '/admin/stock.html';
  a.textContent = '🥬 Stock Today';
  a.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:50;background:#0b6b3a;color:#fff;' +
    'padding:10px 16px;border-radius:24px;font:600 14px "Plus Jakarta Sans",system-ui,sans-serif;' +
    'text-decoration:none;box-shadow:0 4px 14px rgba(0,0,0,.25)';
  document.body.appendChild(a);
})();
