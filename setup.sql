-- Canada Elective Tracker — Supabase setup
-- Run once in: Supabase dashboard → SQL Editor → New query → paste → Run.
-- The PIN (5913) is already baked in below. Safe to run in an existing project:
-- it only creates one uniquely-named table (elective_tracker) and two functions
-- (tracker_get / tracker_set), and will not alter anything else.

create extension if not exists pgcrypto;

create table if not exists elective_tracker (
  id int primary key default 1,
  pin_hash text not null,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz default now()
);

-- Row Level Security on, with no policies: the table is unreachable through the
-- public REST API. The only doors are the two functions below, which require the PIN.
alter table elective_tracker enable row level security;

insert into elective_tracker (id, pin_hash, data)
values (1, encode(digest('5913', 'sha256'), 'hex'), '{}'::jsonb)
on conflict (id) do nothing;

create or replace function tracker_get(pin text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare row_data jsonb;
begin
  select data into row_data from elective_tracker
   where id = 1 and pin_hash = encode(digest(pin, 'sha256'), 'hex');
  if row_data is null then raise exception 'invalid pin'; end if;
  return row_data;
end $$;

create or replace function tracker_set(pin text, new_data jsonb)
returns void language plpgsql security definer set search_path = public as $$
begin
  update elective_tracker set data = new_data, updated_at = now()
   where id = 1 and pin_hash = encode(digest(pin, 'sha256'), 'hex');
  if not found then raise exception 'invalid pin'; end if;
end $$;

revoke all on function tracker_get(text) from public;
revoke all on function tracker_set(text, jsonb) from public;
grant execute on function tracker_get(text) to anon;
grant execute on function tracker_set(text, jsonb) to anon;

-- To change the PIN later, run:
--   update elective_tracker
--     set pin_hash = encode(digest('NEW-PIN', 'sha256'), 'hex')
--     where id = 1;
