# Staff admin (`/staff`)

A simple phone-friendly page for shop staff: mark products available / not available, edit
sizes, photo, label, and add new products. English + Tamil labels, no GitHub account needed.

URL: `https://am-veg.vercel.app/staff`

## One-time setup (owner)

1. **Create a GitHub token** (GitHub → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens). Repository access: **only** `AjithRithik/AM-vegetables`.
   Permissions: **Contents → Read and write**. Set a long expiry and note the date.
2. **Add environment variables in Vercel** (Project → Settings → Environment Variables, Production):
   - `GITHUB_TOKEN` — the token from step 1
   - `ADMIN_PASSWORD` — the shop password staff will type (make it long)
   - `SESSION_SECRET` — optional, any long random text (otherwise the password is used)
3. **Redeploy** so the variables take effect.

## How it works

`staff/index.html` talks to `api/admin/*` (Vercel functions). The functions check the password,
then commit changes to `content/products/<id>.json` (and photos to `images/uploads/products/`)
on `main` using the server-side token. Vercel redeploys and rebuilds `content/products.json`
(see `scripts/build-products.cjs`), so the app shows the change in about a minute.

## Notes

- Change the password: edit `ADMIN_PASSWORD` in Vercel and redeploy. Existing logins last 12 hours.
- If the token expires, saving fails — create a new one and update `GITHUB_TOKEN`.
- The **Shop** tab lets staff change all text settings in `content/shop.json` via `api/admin/shop.js`:
  WhatsApp and call numbers, shop name, taglines, open/closed switch, hours, payment note, banner,
  no-advance-payment message, how-it-works steps, footer badges and delivery pincodes. Only the logo
  and category icons stay owner-only in `/admin/`.
- On the **Stock** tab, staff can only change stock, featured flag, label, short line, sizes and photo, and add products.
  Everything else (descriptions, Tamil text, pairing, etc.) is edited in the owner CMS at `/admin/`.
- Products added without a photo have an empty image. `npm run catalog:validate` requires images,
  so add the photo before running it.
