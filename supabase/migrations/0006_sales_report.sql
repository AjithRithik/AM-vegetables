-- Sales report for the admin Reports tab. Run after 0001-0005.
--
-- Runs with the caller's permissions (security invoker), so row level security applies:
-- the owner's numbers cover every location, a vendor's cover only their own location(s).
-- Dates are grouped by Indian time. p_to is exclusive (pass the start of the day AFTER the last day).

create index if not exists orders_created_idx on public.orders (created_at desc);

create or replace function public.sales_report(
  p_from timestamptz,
  p_to timestamptz,
  p_location uuid default null,
  p_statuses text[] default array['confirmed','delivered']
) returns jsonb
language sql stable security invoker set search_path = public as $$
  with o as (
    select id, location_id, total, created_at
      from public.orders
     where created_at >= p_from and created_at < p_to
       and status = any(p_statuses)
       and (p_location is null or location_id = p_location)
  ),
  li as (
    select i.name_en, i.quantity, i.line_total, coalesce(c.name_en, 'Other') as category
      from public.order_items i
      join o on o.id = i.order_id
      left join public.products p on p.id = i.product_id
      left join public.categories c on c.id = p.category_id
  )
  select jsonb_build_object(
    'summary', jsonb_build_object(
      'orders',    (select count(*) from o),
      'sales',     (select coalesce(sum(total), 0) from o),
      'avg_order', (select coalesce(round(avg(total), 2), 0) from o),
      'items',     (select coalesce(sum(quantity), 0) from li)
    ),
    'by_day', (
      select coalesce(jsonb_agg(d order by d.day), '[]'::jsonb) from (
        select to_char((created_at at time zone 'Asia/Kolkata')::date, 'YYYY-MM-DD') as day,
               count(*) as orders, sum(total) as sales
          from o group by 1) d
    ),
    'by_location', (
      select coalesce(jsonb_agg(x order by x.sales desc), '[]'::jsonb) from (
        select l.name_en as location, count(*) as orders, sum(o.total) as sales
          from o join public.locations l on l.id = o.location_id
         group by l.name_en) x
    ),
    'products', (
      select coalesce(jsonb_agg(x order by x.revenue desc), '[]'::jsonb) from (
        select name_en as product, category, sum(quantity) as qty, sum(line_total) as revenue
          from li group by name_en, category
         order by sum(line_total) desc limit 300) x
    ),
    'categories', (
      select coalesce(jsonb_agg(x order by x.revenue desc), '[]'::jsonb) from (
        select category, sum(quantity) as qty, sum(line_total) as revenue
          from li group by category) x
    )
  );
$$;

revoke all on function public.sales_report(timestamptz, timestamptz, uuid, text[]) from public, anon;
grant execute on function public.sales_report(timestamptz, timestamptz, uuid, text[]) to authenticated;
