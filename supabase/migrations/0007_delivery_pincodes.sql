-- Enforce each location's delivery pincodes when an order is placed. Run after 0001-0006.
--
-- A location's pincodes are set in the admin (Locations -> Edit -> Delivery pincodes) and stored in
-- location_settings.pincodes as [{pincode, area, active}].
--   * If the location has at least one ACTIVE pincode, orders to any other pincode are refused.
--   * If it has none, it accepts any pincode (so a new location is not blocked before it is set up).
-- Same function as 0005, plus the pincode check.

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
  v_pins     jsonb;
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

  -- delivery area
  select pincodes into v_pins from public.location_settings where location_id = p_location;
  if v_pins is not null and jsonb_typeof(v_pins) = 'array'
     and exists (select 1 from jsonb_array_elements(v_pins) e where coalesce((e->>'active')::boolean, true)) then
    if not exists (select 1 from jsonb_array_elements(v_pins) e
                    where coalesce((e->>'active')::boolean, true) and e->>'pincode' = v_pin) then
      raise exception 'Sorry, we do not deliver to pincode % from this location.', coalesce(nullif(v_pin, ''), '(none)');
    end if;
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
