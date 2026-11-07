-- Starting delivery pincodes for each location (real pincodes from India Post / OpenStreetMap).
-- This is only a STARTING LIST: each town also has villages and neighbouring pincodes. Check it and
-- change it in the admin: Locations -> Edit -> Delivery pincodes.
--
--   * Safe to re-run: it only fills a location whose list is still empty, never overwrites your edits.
--   * Once a location has at least one active pincode, orders to any other pincode are refused.
--
-- Run in: Supabase Dashboard -> SQL Editor.

update public.location_settings ls
   set pincodes = '[
     {"pincode": "626123", "area": "Sivakasi", "active": true},
     {"pincode": "626124", "area": "Sivakasi West", "active": true},
     {"pincode": "626189", "area": "Sivakasi East", "active": true},
     {"pincode": "626130", "area": "Thiruthangal", "active": true}
   ]'::jsonb
  from public.locations l
 where l.id = ls.location_id and l.slug = 'sivakasi'
   and (ls.pincodes is null or ls.pincodes = '[]'::jsonb);

update public.location_settings ls
   set pincodes = '[
     {"pincode": "626125", "area": "Srivilliputtur", "active": true},
     {"pincode": "626135", "area": "Srivilliputtur Court Complex", "active": true}
   ]'::jsonb
  from public.locations l
 where l.id = ls.location_id and l.slug = 'srivilliputtur'
   and (ls.pincodes is null or ls.pincodes = '[]'::jsonb);

update public.location_settings ls
   set pincodes = '[
     {"pincode": "626126", "area": "Krishnan Kovil", "active": true}
   ]'::jsonb
  from public.locations l
 where l.id = ls.location_id and l.slug = 'krishnan-kovil'
   and (ls.pincodes is null or ls.pincodes = '[]'::jsonb);

-- Check
select l.name_en as location, ls.pincodes
  from public.location_settings ls join public.locations l on l.id = ls.location_id
 order by l.sort;
