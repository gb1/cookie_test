-- Cork Harbour Boats - initial schema.
--
-- Apply this once via the Supabase SQL editor (Dashboard -> SQL -> New query
-- -> paste -> Run). Idempotent: safe to re-run.

-- ─── extensions ────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ─── enums ─────────────────────────────────────────────────────────────
do $$ begin
  create type public.ride_status as enum (
    'requested',
    'accepted',
    'driverEnRoute',
    'arrivedAtPickup',
    'inProgress',
    'completed',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.user_role as enum ('passenger', 'driver');
exception when duplicate_object then null; end $$;

-- ─── profiles ──────────────────────────────────────────────────────────
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text not null,
  role public.user_role not null default 'passenger',
  vessel_name text,
  vessel_capacity int,
  is_online_driver boolean not null default false,
  updated_at timestamptz not null default now()
);

-- ─── rides ─────────────────────────────────────────────────────────────
create table if not exists public.rides (
  id uuid primary key default gen_random_uuid(),

  passenger_id   uuid not null references public.profiles(id) on delete cascade,
  passenger_name text not null,

  driver_id    uuid references public.profiles(id) on delete set null,
  driver_name  text,
  vessel_name  text,

  pickup_lat    double precision not null,
  pickup_lng    double precision not null,
  pickup_label  text not null,
  dropoff_lat   double precision not null,
  dropoff_lng   double precision not null,
  dropoff_label text not null,

  distance_km double precision not null,
  eta_minutes int               not null,
  fare_eur    numeric(10, 2)    not null,

  status      public.ride_status not null default 'requested',
  created_at  timestamptz       not null default now(),
  completed_at timestamptz,
  cancelled_by_user_id uuid
);

create index if not exists rides_status_idx    on public.rides (status);
create index if not exists rides_passenger_idx on public.rides (passenger_id);
create index if not exists rides_driver_idx    on public.rides (driver_id);
create index if not exists rides_created_idx   on public.rides (created_at desc);

-- ─── chat ──────────────────────────────────────────────────────────────
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  ride_id     uuid not null references public.rides(id) on delete cascade,
  sender_id   uuid not null references public.profiles(id) on delete cascade,
  sender_name text not null,
  body        text not null,
  sent_at     timestamptz not null default now()
);

create index if not exists chat_messages_ride_idx
  on public.chat_messages (ride_id, sent_at);

-- ─── auto-create profile on auth signup ────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (
    new.id,
    new.email,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      split_part(new.email, '@', 1)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ─── row level security ────────────────────────────────────────────────
alter table public.profiles      enable row level security;
alter table public.rides         enable row level security;
alter table public.chat_messages enable row level security;

-- profiles: any authed user can read (we need name lookups for ride cards);
-- only the owner can insert / update their own row.
drop policy if exists "profiles read"        on public.profiles;
drop policy if exists "profiles insert self" on public.profiles;
drop policy if exists "profiles update self" on public.profiles;

create policy "profiles read"
  on public.profiles for select
  to authenticated
  using (true);

create policy "profiles insert self"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "profiles update self"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- rides: a row is visible to its passenger, its driver, or to any online
-- driver while the ride is still in 'requested'.
drop policy if exists "ride read"          on public.rides;
drop policy if exists "ride insert"        on public.rides;
drop policy if exists "ride update"        on public.rides;

create policy "ride read"
  on public.rides for select
  to authenticated
  using (
    auth.uid() = passenger_id
    or auth.uid() = driver_id
    or (
      status = 'requested'
      and exists (
        select 1
        from public.profiles p
        where p.id = auth.uid()
          and p.role = 'driver'
          and p.is_online_driver
      )
    )
  );

create policy "ride insert"
  on public.rides for insert
  to authenticated
  with check (auth.uid() = passenger_id);

create policy "ride update"
  on public.rides for update
  to authenticated
  using (
    auth.uid() = passenger_id
    or auth.uid() = driver_id
    or (
      status = 'requested'
      and exists (
        select 1
        from public.profiles p
        where p.id = auth.uid()
          and p.role = 'driver'
          and p.is_online_driver
      )
    )
  )
  with check (
    auth.uid() = passenger_id
    or auth.uid() = driver_id
  );

-- chat: visible only to the ride participants; only participants may write.
drop policy if exists "chat read"   on public.chat_messages;
drop policy if exists "chat insert" on public.chat_messages;

create policy "chat read"
  on public.chat_messages for select
  to authenticated
  using (
    exists (
      select 1
      from public.rides r
      where r.id = chat_messages.ride_id
        and (r.passenger_id = auth.uid() or r.driver_id = auth.uid())
    )
  );

create policy "chat insert"
  on public.chat_messages for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and exists (
      select 1
      from public.rides r
      where r.id = chat_messages.ride_id
        and (r.passenger_id = auth.uid() or r.driver_id = auth.uid())
    )
  );

-- ─── realtime ──────────────────────────────────────────────────────────
-- Make sure these tables are part of the realtime publication so the
-- Flutter clients get push updates.
do $$ begin
  alter publication supabase_realtime add table public.rides;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.chat_messages;
exception when duplicate_object then null; end $$;

do $$ begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object then null; end $$;
