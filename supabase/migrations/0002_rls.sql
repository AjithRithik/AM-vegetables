-- Row Level Security.
--   anon (customers)  : read-only catalogue for active locations
--   vendor            : edit availability / stock / prices / settings of ONLY their locations
--   owner             : everything

alter table public.locations            enable row level security;
alter table public.location_settings    enable row level security;
alter table public.app_settings         enable row level security;
alter table public.categories           enable row level security;
alter table public.images               enable row level security;
alter table public.products             enable row level security;
alter table public.product_packs        enable row level security;
alter table public.location_products    enable row level security;
alter table public.location_pack_prices enable row level security;
alter table public.profiles             enable row level security;
alter table public.vendor_locations     enable row level security;

-- ---- locations
create policy locations_read on public.locations for select using (is_active or public.can_manage_location(id));
create policy locations_owner_write on public.locations for all using (public.is_owner()) with check (public.is_owner());

-- ---- location_settings
create policy ls_read on public.location_settings for select using (true);
create policy ls_insert on public.location_settings for insert with check (public.can_manage_location(location_id));
create policy ls_update on public.location_settings for update
  using (public.can_manage_location(location_id)) with check (public.can_manage_location(location_id));
create policy ls_delete on public.location_settings for delete using (public.is_owner());

-- ---- app_settings (global text): everyone reads, owner writes
create policy app_settings_read on public.app_settings for select using (true);
create policy app_settings_owner_write on public.app_settings for all using (public.is_owner()) with check (public.is_owner());

-- ---- master data: public read, owner write
create policy categories_read on public.categories for select using (true);
create policy categories_owner_write on public.categories for all using (public.is_owner()) with check (public.is_owner());

create policy images_read on public.images for select using (true);
create policy images_owner_write on public.images for all using (public.is_owner()) with check (public.is_owner());

create policy products_read on public.products for select using (is_active or public.is_owner());
create policy products_owner_write on public.products for all using (public.is_owner()) with check (public.is_owner());

create policy packs_read on public.product_packs for select using (true);
create policy packs_owner_write on public.product_packs for all using (public.is_owner()) with check (public.is_owner());

-- ---- location_products: customers see available rows; staff see/edit their locations
create policy lprod_read on public.location_products for select
  using (is_available or public.can_manage_location(location_id));
create policy lprod_insert on public.location_products for insert with check (public.can_manage_location(location_id));
create policy lprod_update on public.location_products for update
  using (public.can_manage_location(location_id)) with check (public.can_manage_location(location_id));
create policy lprod_delete on public.location_products for delete using (public.is_owner());

-- ---- prices
create policy price_read on public.location_pack_prices for select
  using (price is not null or public.can_manage_location(location_id));
create policy price_insert on public.location_pack_prices for insert with check (public.can_manage_location(location_id));
create policy price_update on public.location_pack_prices for update
  using (public.can_manage_location(location_id)) with check (public.can_manage_location(location_id));
create policy price_delete on public.location_pack_prices for delete using (public.can_manage_location(location_id));

-- ---- staff tables
create policy profiles_read on public.profiles for select using (user_id = auth.uid() or public.is_owner());
create policy profiles_owner_write on public.profiles for all using (public.is_owner()) with check (public.is_owner());

create policy vl_read on public.vendor_locations for select using (user_id = auth.uid() or public.is_owner());
create policy vl_owner_write on public.vendor_locations for all using (public.is_owner()) with check (public.is_owner());
