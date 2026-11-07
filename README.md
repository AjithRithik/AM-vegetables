# AM Vegetables

One app, several shops. Each location (Sivakasi, Krishnan Kovil, Srivilliputtur, ...) has its own
products, prices, address, WhatsApp number and team. Customers pick their location first and order
over WhatsApp; the order is also saved so the owner and the shop's vendor see it in the admin.

| Part | Folder | What it is |
|---|---|---|
| Customer app | `app/` | Flutter app (Android / iOS / web). Reads the catalogue from Supabase. |
| Admin panel | `staff/` | Web page at `/staff`: products, prices, orders, locations, team. |
| Server function | `api/admin/users.js` | Owner-only: creates vendor logins (needs the secret key). |
| Database | `supabase/migrations/` | Tables, security rules, order function. |
| Tools | `scripts/` | Data migration, local dev server. |
| `content/` | | The original product files. Only used as the source for `npm run db:migrate`. |

## Roles
- **Owner**: everything. Adds locations, products and sizes, sets prices for any location, creates vendors.
- **Vendor**: only their own location(s): stock, availability, prices, shop details, orders.
- **Customer**: anonymous, read-only catalogue, can place an order.

Security is enforced by the database (Row Level Security), not by the pages.

## One-time setup
1. **Supabase**: in the SQL editor run, in order, `supabase/migrations/0001` to `0005`.
   Optional: `supabase/seed/sample_prices.sql` fills made-up prices for testing.
2. **Keys**: copy `.env.example` to `.env.local` and fill it in
   (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` = the `sb_secret_...` key, owner phone and password).
   The secret key is server-side only; never put it in `staff/` or `app/`.
3. **Load the data**: `npm install`, then `npm run db:migrate` (safe to re-run; it never overwrites prices or vendor edits).
4. **Public key**: `staff/config.js` and `app/lib/config.dart` hold the publishable (anon) key. That one is meant to be public.
5. **Vercel**: set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` as environment variables (used only by `api/admin/users.js`).

## Run locally
```
npm run dev:admin        # admin panel + api at http://localhost:8080/staff
cd app && flutter run --dart-define-from-file=env/local.json
cd app && flutter build apk --release --dart-define-from-file=env/prod.json
```

## Day to day
See `docs/staff-admin.md` for the admin walkthrough (prices, vendors, orders).
