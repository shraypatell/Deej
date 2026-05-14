-- 0001_initial_schema.sql
-- Deej v1 schema. Apply with `supabase db push` once Supabase project is created.

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- USERS ------------------------------------------------------------------
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~* '^[a-z0-9_.-]{3,30}$'),
  display_name text,
  bio text check (char_length(bio) <= 160),
  avatar_url text,
  location text,
  onboarding_completed boolean not null default false,
  taste_vector jsonb,
  taste_vector_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- EVENTS (canonical, shared across users) --------------------------------
create table public.events (
  id uuid primary key default uuid_generate_v4(),
  artist_name text not null,
  artist_name_normalized text generated always as
    (lower(regexp_replace(artist_name, '[^a-z0-9]', '', 'g'))) stored,
  venue_name text not null,
  venue_name_normalized text generated always as
    (lower(regexp_replace(venue_name, '[^a-z0-9]', '', 'g'))) stored,
  city text,
  event_date date not null,
  start_time timestamptz,
  promoted_by_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create unique index events_dedup_idx on public.events
  (artist_name_normalized, venue_name_normalized, event_date);

-- EVENT LOGS -------------------------------------------------------------
create type public.event_log_archive_status as enum ('active', 'archived');

create table public.event_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  rating_artist_performance smallint not null check (rating_artist_performance between 1 and 10),
  rating_crowd_energy       smallint not null check (rating_crowd_energy between 1 and 10),
  rating_venue              smallint not null check (rating_venue between 1 and 10),
  rating_lighting_visuals   smallint not null check (rating_lighting_visuals between 1 and 10),
  rating_music_selection    smallint not null check (rating_music_selection between 1 and 10),
  rating_atmosphere_vibe    smallint not null check (rating_atmosphere_vibe between 1 and 10),
  rating_value              smallint not null check (rating_value between 1 and 10),
  aggregate_score numeric(3,2) not null,
  notes text check (char_length(notes) <= 1000),
  photo_urls text[] default '{}',
  status public.event_log_archive_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, event_id)
);

create index event_logs_user_idx  on public.event_logs (user_id, created_at desc);
create index event_logs_event_idx on public.event_logs (event_id);

-- FRIENDSHIPS ------------------------------------------------------------
create type public.friendship_status as enum ('pending', 'accepted', 'blocked');

create table public.friendships (
  id uuid primary key default uuid_generate_v4(),
  requester_id uuid not null references public.users(id) on delete cascade,
  recipient_id uuid not null references public.users(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> recipient_id),
  unique (requester_id, recipient_id)
);

create index friendships_requester_idx on public.friendships (requester_id, status);
create index friendships_recipient_idx on public.friendships (recipient_id, status);

-- ACTIVITY FEED ----------------------------------------------------------
create type public.activity_type as enum (
  'rated_event', 'going_to_event', 'milestone', 'added_to_want', 'friend_joined'
);

create table public.activity_feed (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  type public.activity_type not null,
  subject_event_id uuid references public.events(id) on delete cascade,
  subject_user_id  uuid references public.users(id)  on delete cascade,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index activity_feed_user_idx on public.activity_feed (user_id, created_at desc);

create table public.activity_reactions (
  id uuid primary key default uuid_generate_v4(),
  activity_id uuid not null references public.activity_feed(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  unique (activity_id, user_id, emoji)
);

-- WANT LIST --------------------------------------------------------------
create table public.want_list (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, event_id)
);
