-- Canada Elective Tracker — Supabase setup
-- For a DEDICATED project (nothing else lives here), so the public schema is used.
-- Run once in: Supabase dashboard → SQL Editor → New query → paste → Run.
-- PIN (5913) is baked in.

create extension if not exists pgcrypto;

create table if not exists public.elective_tracker (
  id int primary key default 1,
  pin_hash text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- RLS on with no policies: the table is unreachable through the REST API directly.
-- The only access is via the two PIN-checked functions below.
alter table public.elective_tracker enable row level security;

insert into public.elective_tracker (id, pin_hash, data)
values (1, encode(digest('5913', 'sha256'), 'hex'), '{}'::jsonb)
on conflict (id) do nothing;

create or replace function public.tracker_get(pin text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare row_data jsonb;
begin
  select data into row_data from public.elective_tracker
   where id = 1 and pin_hash = encode(digest(pin, 'sha256'), 'hex');
  if row_data is null then raise exception 'invalid pin'; end if;
  return row_data;
end $$;

create or replace function public.tracker_set(pin text, new_data jsonb)
returns void language plpgsql security definer
set search_path = public, extensions as $$
begin
  update public.elective_tracker set data = new_data, updated_at = now()
   where id = 1 and pin_hash = encode(digest(pin, 'sha256'), 'hex');
  if not found then raise exception 'invalid pin'; end if;
end $$;

revoke all on function public.tracker_get(text) from public;
revoke all on function public.tracker_set(text, jsonb) from public;
grant execute on function public.tracker_get(text) to anon;
grant execute on function public.tracker_set(text, jsonb) to anon;

-- To change the PIN later:
--   update public.elective_tracker
--     set pin_hash = encode(digest('NEW-PIN', 'sha256'), 'hex') where id = 1;
