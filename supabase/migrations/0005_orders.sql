-- Orders. Customers (anonymous) can only PLACE an order through place_order(); they cannot read,
-- list or change orders. Staff read the orders of their own locations and may only change the status.
-- Run after 0001-0004.

create table if not exists public.orders (
  id             uuid primary key default gen_random_uuid(),
  order_no       bigint generated always as identity (start with 1001) unique,
  location_id    uuid not null references public.locations(id),
  customer_name  text not null,
  customer_phone text not null,
  alt_phone      text not null default '',
  address        text not null,
  landmark       text not null default '',
  pincode        text not null default '',
  map_link       text not null default '',
  notes          text not null default '',
  total          numeric(10,2) not null default 0,
  status         text not null default 'new' check (status in ('new','confirmed','delivered','cancelled')),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  updated_by     uuid references auth.users(id)
);
create index if not exists orders_location_created_idx on public.orders (location_id, created_at desc);
create index if not exists orders_status_idx on public.orders (status);

-- Snapshot of what was ordered (names and prices as they were at order time).
create table if not exists public.order_items (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  product_id  text,
  pack_id     uuid,
  name_en     text not null,
  name_ta     text not null default '',
  pack_label  text not null,
  unit_price  numeric(10,2) not null,
  quantity    int not null check (quantity between 1 and 100),
  line_total  numeric(10,2) not null,
  note        text not null default ''
);
create index if not exists order_items_order_idx on public.order_items (order_id);

-- ---------------------------------------------------------------- security
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

create policy orders_staff_read on public.orders for select using (public.can_manage_location(location_id));
create policy orders_staff_update on public.orders for update
  using (public.can_manage_location(location_id)) with check (public.can_manage_location(location_id));
create policy orders_owner_delete on public.orders for delete using (public.is_owner());
create policy order_items_staff_read on public.order_items for select using (
  exists (select 1 from public.orders o where o.id = order_id and public.can_manage_location(o.location_id)));
-- No insert policies: the only way to create an order is the place_order() function below.

-- Staff can change the status only, never the customer's details, items or total.
revoke update on public.orders from anon, authenticated;
grant  update (status) on public.orders to authenticated;

create or replace function public.touch_order() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  new.updated_by = auth.uid();
  return new;
end $$;
drop trigger if exists trg_orders_touch on public.orders;
create trigger trg_orders_touch before update on public.orders for each row execute function public.touch_order();

-- ---------------------------------------------------------------- place_order
-- p_items: [{ "pack_id": "<uuid>", "count": 2, "note": "optional" }]
-- Names and prices are read from the database here, so a customer cannot send their own price.
create or replace function public.place_order(p_location uuid, p_customer jsonb, p_items jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_name    text := left(trim(coalesce(p_customer->>'name', '')), 100);
  v_phone   text := left(trim(coalesce(p_customer->>'phone', '')), 20);
  v_alt     text := left(trim(coalesce(p_customer->>'alt_phone', '')), 20);
  v_address text := left(trim(coalesce(p_customer->>'address', '')), 400);
  v_land    text := left(trim(coalesce(p_customer->>'landmark', '')), 200);
  v_pin     text := left(trim(coalesce(p_customer->>'pincode', '')), 10);
  v_map     text := left(trim(coalesce(p_customer->>'map_link', '')), 300);
  v_notes   text := left(trim(coalesce(p_customer->>'notes', '')), 500);
  v_order_id uuid;
  v_order_no bigint;
  v_total    numeric := 0;
  it   jsonb;
  pk   record;
  qty  int;
  line numeric;
begin
  if not exists (select 1 from public.locations where id = p_location and is_active) then
    raise exception 'This location is not available right now.';
  end if;
  if length(v_name) < 2 then raise exception 'Please enter your name.'; end if;
  if length(regexp_replace(v_phone, '\D', '', 'g')) < 10 then raise exception 'Please enter a valid phone number.'; end if;
  if length(v_address) < 5 then raise exception 'Please enter your delivery address.'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 or jsonb_array_length(p_items) > 100 then
    raise exception 'Your cart is empty.';
  end if;

  insert into public.orders (location_id, customer_name, customer_phone, alt_phone, address, landmark, pincode, map_link, notes)
  values (p_location, v_name, v_phone, v_alt, v_address, v_land, v_pin, v_map, v_notes)
  returning id, order_no into v_order_id, v_order_no;

  for it in select * from jsonb_array_elements(p_items) loop
    qty := coalesce((it->>'count')::int, 1);
    if qty < 1 or qty > 100 then raise exception 'Invalid quantity.'; end if;

    select pack.id as pack_id, pack.label_en, prod.id as product_id, prod.name_en, prod.name_ta, pr.price, lp.in_stock
      into pk
      from public.product_packs pack
      join public.products prod on prod.id = pack.product_id and prod.is_active
      join public.location_products lp on lp.product_id = prod.id and lp.location_id = p_location and lp.is_available
      join public.location_pack_prices pr on pr.pack_id = pack.id and pr.location_id = p_location and pr.price is not null
     where pack.id = (it->>'pack_id')::uuid;

    if not found then
      raise exception 'An item in your cart is no longer available. Please refresh and try again.';
    end if;
    if not pk.in_stock then raise exception '% is out of stock right now.', pk.name_en; end if;

    line := pk.price * qty;
    insert into public.order_items (order_id, product_id, pack_id, name_en, name_ta, pack_label, unit_price, quantity, line_total, note)
    values (v_order_id, pk.product_id, pk.pack_id, pk.name_en, pk.name_ta, pk.label_en, pk.price, qty, line, left(coalesce(it->>'note', ''), 200));
    v_total := v_total + line;
  end loop;

  update public.orders set total = v_total where id = v_order_id;
  return jsonb_build_object('order_no', v_order_no, 'total', v_total);
end $$;

revoke all on function public.place_order(uuid, jsonb, jsonb) from public;
grant execute on function public.place_order(uuid, jsonb, jsonb) to anon, authenticated;
