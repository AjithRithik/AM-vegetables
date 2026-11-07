-- Staff log in with a mobile number. Supabase Auth still needs an email-shaped id, so the
-- panel maps  919876543210  ->  919876543210@phone.am-veg.vercel.app  (never emailed).
-- This column keeps the real phone number for display in the Team tab.
alter table public.profiles add column if not exists phone text not null default '';

update public.profiles
   set phone = split_part(email, '@', 1)
 where phone = '' and email like '%@phone.am-veg.vercel.app';
