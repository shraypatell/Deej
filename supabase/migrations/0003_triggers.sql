-- 0003_triggers.sql
-- Server-side automation: auto-create activity_feed rows when users rate
-- events; auto-bump updated_at on row updates.

-- Activity feed: rated_event ------------------------------------------------
create or replace function public.add_rated_event_activity()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.activity_feed (user_id, type, subject_event_id, metadata)
  values (
    new.user_id,
    'rated_event',
    new.event_id,
    jsonb_build_object('score', new.aggregate_score)
  );
  return new;
end;
$$;

drop trigger if exists on_event_log_insert on public.event_logs;
create trigger on_event_log_insert
after insert on public.event_logs
for each row execute function public.add_rated_event_activity();

-- updated_at touch helper ---------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists users_touch_updated_at on public.users;
create trigger users_touch_updated_at
before update on public.users
for each row execute function public.touch_updated_at();

drop trigger if exists event_logs_touch_updated_at on public.event_logs;
create trigger event_logs_touch_updated_at
before update on public.event_logs
for each row execute function public.touch_updated_at();

drop trigger if exists friendships_touch_updated_at on public.friendships;
create trigger friendships_touch_updated_at
before update on public.friendships
for each row execute function public.touch_updated_at();
