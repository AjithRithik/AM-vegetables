-- SAMPLE prices for every pack in every location, so the catalogue is not empty while testing.
-- These are made-up, realistic-looking rupee amounts, NOT real prices. Replace them in the admin.
--
--  * Safe to re-run: it only fills prices that are still empty, never overwrites a price you set.
--  * Each location gets a slightly different price (about -3% to +3%) so you can see the difference.
--  * Price is computed per kg / per piece / per bunch from the category, then multiplied by pack size.
--
-- Run in: Supabase Dashboard -> SQL Editor.
-- Remove ONLY the sample prices later (prices saved from the admin panel keep the editor's id):
--   delete from public.location_pack_prices where updated_by is null;

with ranges(cat, sold, lo, hi) as (values
  ('leafy-greens',     'bunch',  8,  20),   -- Rs per bunch
  ('herbs',            'bunch',  8,  15),
  ('roots-and-tubers', 'weight', 35, 90),   -- Rs per kg
  ('vegetables',       'weight', 25, 90),
  ('vegetables',       'piece',  20, 50),   -- Rs per piece
  ('leaves',           'piece',  3,  10),
  ('fruits',           'weight', 70, 260),
  ('fruits',           'piece',  40, 150),
  ('fresh-essentials', 'weight', 60, 280),
  ('fresh-essentials', 'piece',  10, 40)
),
calc as (
  select
    l.id  as location_id,
    pk.id as pack_id,
    greatest(1, round(
      (r.lo + (abs(hashtext(p.id)) % 1000) / 1000.0 * (r.hi - r.lo))   -- unit price, stable per product
      * pk.quantity                                                    -- pack size (0.5 kg, 2 pieces, ...)
      * (0.97 + (abs(hashtext(l.slug)) % 7) / 100.0)                   -- small per-location difference
    )) as price
  from public.product_packs pk
  join public.products   p on p.id = pk.product_id and p.is_active
  join public.categories c on c.id = p.category_id
  join ranges r on r.cat = c.slug and r.sold = p.sold_by
  cross join public.locations l
)
insert into public.location_pack_prices (location_id, pack_id, price)
select location_id, pack_id, price from calc
on conflict (location_id, pack_id) do update
  set price = excluded.price
  where public.location_pack_prices.price is null;

-- Check: packs that still have no price in some location (should return 0 rows)
select p.id, pk.label_en, l.name_en as location
from public.product_packs pk
join public.products p on p.id = pk.product_id and p.is_active
cross join public.locations l
left join public.location_pack_prices pr on pr.pack_id = pk.id and pr.location_id = l.id
where pr.price is null
limit 20;
