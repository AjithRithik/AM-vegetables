-- AM Vegetables: multi-location catalogue schema.
-- Shared master data (products, packs, categories, images) + per-location
-- availability, stock and prices. Run in the Supabase SQL editor (or `supabase db push`).

create extension if not exists pgcrypto;

-- ------------------------------------------------------------------ locations
create table if not exists public.locations (
  id         uuid primary key default gen_random_uuid(),
  slug       text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name_en    text not null,
  name_ta    text not null default '',
  is_active  boolean not null default true,
  sort       int not null default 0,
  created_at timestamptz not null default now()
);

-- Per-location shop details (WhatsApp number, hours, banner, delivery pincodes...).
create table if not exists public.location_settings (
  location_id  uuid primary key references public.locations(id) on delete cascade,
  whatsapp     text not null default '',
  phone        text not null default '',
  hours        text not null default '',
  is_open      boolean not null default true,
  payment_note text not null default '',
  banner       jsonb not null default '{}'::jsonb,
  pincodes     jsonb not null default '[]'::jsonb,   -- [{pincode, area, active}]
  updated_at   timestamptz not null default now()
);

-- Global, shared-by-all-locations app text (shop name, logo, taglines, how-it-works...).
create table if not exists public.app_settings (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------------ master catalogue
create table if not exists public.categories (
  id      uuid primary key default gen_random_uuid(),
  slug    text not null unique,
  name_en text not null unique,
  name_ta text not null default '',
  icon    text not null default '',
  sort    int not null default 0
);

-- One row per photo. Products reference it by id, so one URL is reused by every vendor.
create table if not exists public.images (
  id         uuid primary key default gen_random_uuid(),
  url        text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id             text primary key check (id ~ '^[a-z0-9-]+$'),   -- stable slug, never change
  name_en        text not null,
  name_ta        text not null default '',
  name_alt       text not null default '',
  category_id    uuid not null references public.categories(id),
  image_id       uuid references public.images(id),
  gallery        uuid[] not null default '{}',
  origin         text not null default '',
  tagline        text not null default '',
  badge          text not null default '',                       -- default badge; a location can override
  description_en text not null default '',
  description_ta text not null default '',
  highlights     text[] not null default '{}',
  trust_points   jsonb not null default '[]'::jsonb,
  harvest_note   jsonb,
  sold_by        text not null default 'weight' check (sold_by in ('weight','piece','bunch')),
  allow_note     boolean not null default true,
  note_hint      text not null default '',
  paired_with    text[] not null default '{}',
  keywords       text[] not null default '{}',
  sort           int not null default 0,
  is_active      boolean not null default true,                  -- owner can retire a product everywhere
  updated_at     timestamptz not null default now()
);
create index if not exists products_category_idx on public.products(category_id);

create table if not exists public.product_packs (
  id         uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id) on delete cascade,
  label_en   text not null,
  label_ta   text not null default '',
  quantity   numeric not null,
  unit       text not null check (unit in ('kg','piece','bunch')),
  is_default boolean not null default false,
  popular    boolean not null default false,
  note       text not null default '',
  sort       int not null default 0,
  unique (product_id, sort)
);

-- ------------------------------------------------------------------ per-location data
create table if not exists public.location_products (
  location_id  uuid not null references public.locations(id) on delete cascade,
  product_id   text not null references public.products(id) on delete cascade,
  is_available boolean not null default true,    -- sold at this location at all?
  in_stock     boolean not null default true,    -- false => shown greyed out
  featured     boolean not null default false,
  badge        text,                              -- null => use products.badge
  updated_at   timestamptz not null default now(),
  primary key (location_id, product_id)
);

create table if not exists public.location_pack_prices (
  location_id uuid not null references public.locations(id) on delete cascade,
  pack_id     uuid not null references public.product_packs(id) on delete cascade,
  price       numeric(10,2) check (price is null or price >= 0),
  mrp         numeric(10,2) check (mrp is null or mrp >= 0),
  updated_by  uuid references auth.users(id),
  updated_at  timestamptz not null default now(),
  primary key (location_id, pack_id)
);

-- ------------------------------------------------------------------ staff
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role    text not null check (role in ('owner','vendor')),
  name    text not null default '',
  email   text not null default ''
);

create table if not exists public.vendor_locations (
  user_id     uuid not null references auth.users(id) on delete cascade,
  location_id uuid not null references public.locations(id) on delete cascade,
  primary key (user_id, location_id)
);

-- ------------------------------------------------------------------ helpers
create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where user_id = auth.uid() and role = 'owner');
$$;

create or replace function public.can_manage_location(loc uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_owner() or exists (
    select 1
    from public.vendor_locations vl
    join public.profiles p on p.user_id = vl.user_id
    where vl.user_id = auth.uid() and vl.location_id = loc and p.role = 'vendor');
$$;

create or replace function public.touch_row() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

create or replace function public.touch_price() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end $$;

drop trigger if exists trg_products_touch on public.products;
create trigger trg_products_touch before update on public.products for each row execute function public.touch_row();
drop trigger if exists trg_lp_touch on public.location_products;
create trigger trg_lp_touch before update on public.location_products for each row execute function public.touch_row();
drop trigger if exists trg_ls_touch on public.location_settings;
create trigger trg_ls_touch before update on public.location_settings for each row execute function public.touch_row();
drop trigger if exists trg_price_touch on public.location_pack_prices;
create trigger trg_price_touch before insert or update on public.location_pack_prices for each row execute function public.touch_price();

-- ------------------------------------------------------------------ app read model
-- What the Flutter app reads: one row per product per location, only products that are
-- available at that location AND have at least one priced pack. Unpriced packs are left out.
-- security_invoker => the caller's RLS applies.
create or replace view public.v_catalogue with (security_invoker = true) as
select
  lp.location_id,
  p.id            as id,
  p.name_en, p.name_ta, p.name_alt,
  c.name_en       as category_en,
  c.name_ta       as category_ta,
  c.sort          as category_sort,
  img.url         as image,
  (select coalesce(jsonb_agg(gi.url order by g.ord), '[]'::jsonb)
     from unnest(p.gallery) with ordinality as g(gid, ord)
     join public.images gi on gi.id = g.gid) as gallery,
  p.origin, p.tagline,
  coalesce(nullif(lp.badge, ''), p.badge) as badge,
  p.description_en, p.description_ta,
  to_jsonb(p.highlights) as highlights,
  p.trust_points, p.harvest_note,
  p.sold_by, p.allow_note, p.note_hint,
  to_jsonb(p.paired_with) as paired_with,
  to_jsonb(p.keywords)    as keywords,
  p.sort,
  lp.in_stock, lp.featured,
  packs.packs
from public.location_products lp
join public.locations l on l.id = lp.location_id and l.is_active
join public.products p on p.id = lp.product_id and p.is_active
join public.categories c on c.id = p.category_id
left join public.images img on img.id = p.image_id
join lateral (
  select jsonb_agg(jsonb_build_object(
           'id', pk.id, 'label_en', pk.label_en, 'label_ta', pk.label_ta,
           'quantity', pk.quantity, 'unit', pk.unit, 'is_default', pk.is_default,
           'popular', pk.popular, 'note', pk.note,
           'price', pr.price, 'mrp', pr.mrp) order by pk.sort) as packs
  from public.product_packs pk
  join public.location_pack_prices pr
    on pr.pack_id = pk.id and pr.location_id = lp.location_id and pr.price is not null
  where pk.product_id = p.id
) packs on packs.packs is not null
where lp.is_available;

grant select on public.v_catalogue to anon, authenticated;
