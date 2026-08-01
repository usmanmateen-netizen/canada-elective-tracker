-- Canada Elective Tracker — Supabase setup
-- For a DEDICATED project (nothing else lives here), so the public schema is used.
-- Run once in: Supabase dashboard → SQL Editor → New query → paste → Run.
-- Password (nehel84) is baked in as a sha256 hash. (Live DB updated to this on 2026-07-23.)

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
values (1, encode(digest('nehel84', 'sha256'), 'hex'), '{}'::jsonb)
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

-- ============================================================
-- Profile store for the Builder page (builder.html).
-- Separate row/table so a profile submission never clobbers the tracker's
-- 30-second progress sync. Reuses the SAME password hash from elective_tracker,
-- so the one password (nehel84) unlocks both and a password change covers both.
-- ============================================================
create table if not exists public.profile (
  id int primary key default 1,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);
alter table public.profile enable row level security;
insert into public.profile (id, data) values (1, '{}'::jsonb) on conflict (id) do nothing;

create or replace function public.profile_get(pin text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare row_data jsonb;
begin
  if (select pin_hash from public.elective_tracker where id = 1) <> encode(digest(pin, 'sha256'), 'hex')
    then raise exception 'invalid pin'; end if;
  select data into row_data from public.profile where id = 1;
  return coalesce(row_data, '{}'::jsonb);
end $$;

create or replace function public.profile_set(pin text, new_data jsonb)
returns void language plpgsql security definer
set search_path = public, extensions as $$
begin
  if (select pin_hash from public.elective_tracker where id = 1) <> encode(digest(pin, 'sha256'), 'hex')
    then raise exception 'invalid pin'; end if;
  update public.profile set data = new_data, updated_at = now() where id = 1;
end $$;

revoke all on function public.profile_get(text) from public;
revoke all on function public.profile_set(text, jsonb) from public;
grant execute on function public.profile_get(text) to anon;
grant execute on function public.profile_set(text, jsonb) to anon;

-- ============================================================
-- Visit log: one row per successful sign-in, so we can see whether
-- the site is actually being opened (progress edits alone don't show visits).
-- Stores time + which page + browser string. No personal data beyond that.
-- ============================================================
create table if not exists public.visit_log (
  id bigserial primary key,
  at timestamptz not null default now(),
  page text,
  agent text
);
alter table public.visit_log enable row level security;

create or replace function public.visit_ping(pin text, p_page text default null, p_agent text default null)
returns void language plpgsql security definer
set search_path = public, extensions as $$
begin
  if (select pin_hash from public.elective_tracker where id = 1) <> encode(digest(pin, 'sha256'), 'hex')
    then raise exception 'invalid pin'; end if;
  insert into public.visit_log (page, agent) values (left(p_page, 40), left(p_agent, 300));
  -- keep only the most recent 500 rows
  delete from public.visit_log
   where id <= (select max(id) - 500 from public.visit_log);
end $$;

create or replace function public.visit_list(pin text)
returns jsonb language plpgsql security definer
set search_path = public, extensions as $$
declare out_data jsonb;
begin
  if (select pin_hash from public.elective_tracker where id = 1) <> encode(digest(pin, 'sha256'), 'hex')
    then raise exception 'invalid pin'; end if;
  select coalesce(jsonb_agg(t order by t.at desc), '[]'::jsonb) into out_data
    from (select at, page, agent from public.visit_log order by at desc limit 200) t;
  return out_data;
end $$;

revoke all on function public.visit_ping(text, text, text) from public;
revoke all on function public.visit_list(text) from public;
grant execute on function public.visit_ping(text, text, text) to anon;
grant execute on function public.visit_list(text) to anon;
