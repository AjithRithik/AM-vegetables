-- Location address + vendor management helpers. Run after 0001 and 0002.

alter table public.location_settings add column if not exists address  text not null default '';
alter table public.location_settings add column if not exists maps_url text not null default '';

-- Owner assigns a vendor to locations. The login itself is created first in
-- Supabase Dashboard -> Authentication -> Users (Add user, "Auto confirm"); this links it.
create or replace function public.owner_set_vendor(p_email text, p_name text, p_locations uuid[])
returns void language plpgsql security definer set search_path = public, auth as $$
declare uid uuid;
begin
  if not public.is_owner() then raise exception 'Only the owner can manage vendors.'; end if;
  select id into uid from auth.users where lower(email) = lower(trim(p_email));
  if uid is null then
    raise exception 'No login exists for %. Create the user in Supabase Authentication first.', p_email;
  end if;
  if exists (select 1 from public.profiles where user_id = uid and role = 'owner') then
    raise exception 'That account is an owner.';
  end if;
  insert into public.profiles (user_id, role, name, email)
    values (uid, 'vendor', coalesce(p_name, ''), lower(trim(p_email)))
    on conflict (user_id) do update set name = excluded.name, role = 'vendor';
  delete from public.vendor_locations where user_id = uid;
  insert into public.vendor_locations (user_id, location_id)
    select uid, unnest(coalesce(p_locations, '{}'::uuid[]));
end $$;

create or replace function public.owner_remove_vendor(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_owner() then raise exception 'Only the owner can manage vendors.'; end if;
  delete from public.vendor_locations where user_id = p_user;
  delete from public.profiles where user_id = p_user and role = 'vendor';
end $$;

revoke all on function public.owner_set_vendor(text, text, uuid[]) from public, anon;
revoke all on function public.owner_remove_vendor(uuid) from public, anon;
grant execute on function public.owner_set_vendor(text, text, uuid[]) to authenticated;
grant execute on function public.owner_remove_vendor(uuid) to authenticated;
