-- 0002_rls_policies.sql
-- Row-level security for Deej v1. See PLAN.md §3.2.

alter table public.users               enable row level security;
alter table public.events              enable row level security;
alter table public.event_logs          enable row level security;
alter table public.friendships         enable row level security;
alter table public.activity_feed       enable row level security;
alter table public.activity_reactions  enable row level security;
alter table public.want_list           enable row level security;

-- USERS ------------------------------------------------------------------
create policy users_self_update on public.users
  for update using (auth.uid() = id);

create policy users_self_insert on public.users
  for insert with check (auth.uid() = id);

create policy users_public_read on public.users
  for select using (true);

-- EVENTS -----------------------------------------------------------------
create policy events_read on public.events
  for select using (true);

create policy events_insert on public.events
  for insert with check (auth.uid() is not null);

-- EVENT LOGS -------------------------------------------------------------
create policy event_logs_owner_all on public.event_logs
  for all using (auth.uid() = user_id);

create policy event_logs_friends_read on public.event_logs
  for select using (
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = auth.uid() and f.recipient_id = event_logs.user_id)
          or (f.recipient_id = auth.uid() and f.requester_id = event_logs.user_id))
    )
  );

-- FRIENDSHIPS ------------------------------------------------------------
create policy friendships_visible on public.friendships
  for select using (
    auth.uid() = requester_id or auth.uid() = recipient_id
  );

create policy friendships_insert on public.friendships
  for insert with check (auth.uid() = requester_id);

create policy friendships_update on public.friendships
  for update using (
    auth.uid() = recipient_id or auth.uid() = requester_id
  );

-- ACTIVITY FEED ----------------------------------------------------------
create policy activity_visible on public.activity_feed
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = auth.uid() and f.recipient_id = activity_feed.user_id)
          or (f.recipient_id = auth.uid() and f.requester_id = activity_feed.user_id))
    )
  );

create policy activity_insert on public.activity_feed
  for insert with check (auth.uid() = user_id);

-- ACTIVITY REACTIONS -----------------------------------------------------
create policy reactions_visible on public.activity_reactions
  for select using (
    auth.uid() = user_id
    or exists (
      select 1 from public.activity_feed a
      join public.friendships f
        on (f.requester_id = auth.uid() and f.recipient_id = a.user_id)
        or (f.recipient_id = auth.uid() and f.requester_id = a.user_id)
      where a.id = activity_reactions.activity_id and f.status = 'accepted'
    )
  );

create policy reactions_insert on public.activity_reactions
  for insert with check (auth.uid() = user_id);

create policy reactions_delete on public.activity_reactions
  for delete using (auth.uid() = user_id);

-- WANT LIST --------------------------------------------------------------
create policy want_list_owner on public.want_list
  for all using (auth.uid() = user_id);

create policy want_list_friends_read on public.want_list
  for select using (
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = auth.uid() and f.recipient_id = want_list.user_id)
          or (f.recipient_id = auth.uid() and f.requester_id = want_list.user_id))
    )
  );
