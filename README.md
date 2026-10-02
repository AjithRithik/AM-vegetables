# AM Vegetables – Decap CMS

Git-based headless CMS for the AM Vegetables Flutter app.

## Files the Flutter app consumes
| URL path | Content |
|---|---|
| `/content/products.json` | all products (packs, Tamil/English names, featured flag, stock) |
| `/content/shop.json` | shop name, WhatsApp number, hours, banners, pincodes, message template |

Uploaded images land in `/images/uploads/` (product `image` values are paths like `/images/uploads/tomato.jpg`; prefix with your site URL in the app).

## Run locally
```
npm install
npm run dev        # decap-server proxy + static server
```
Open http://localhost:8080/admin/ — edits write straight to `content/*.json`.

## Go live
1. Push this folder to GitHub, set `backend.repo` in `admin/config.yml`.
2. Host it on Netlify (use `name: git-gateway` + Netlify Identity) **or** GitHub Pages / any static host with an OAuth proxy (`base_url`).
3. In Flutter, set `baseUrl` to your site (or `https://raw.githubusercontent.com/<user>/<repo>/main`).
4. Edit at `https://<site>/admin/`. With `editorial_workflow`, content goes live after "Publish".

Notes: keep `id` values stable once the app is released; there are no prices because rates are confirmed daily over WhatsApp.
