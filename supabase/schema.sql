-- GCSE Revision Plan: database setup for Supabase.
-- Paste this whole file into Supabase > SQL Editor > New query, then press Run.
-- Safe to run once on a new project.

-- ---------- tables ----------

create table public.groups (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 1 and 60),
  code        text not null unique,
  settings    jsonb not null default '{}'::jsonb,
  created_by  uuid references auth.users (id) on delete set null,
  created_at  timestamptz not null default now()
);

-- One row per person: their display name, group, and the small summary buddies can see.
create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  display_name  text not null default 'Me' check (char_length(display_name) between 1 and 40),
  group_id      uuid references public.groups (id) on delete set null,
  summary       jsonb,  -- tonight's subjects, this week's count, streak
  studying      jsonb,  -- set while a timer is running: { until, subject }
  updated_at    timestamptz not null default now()
);
create index profiles_group_id_idx on public.profiles (group_id);

-- Each person's full plan (settings, subjects, ticks). Only its owner can read it.
create table public.plans (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  data        jsonb not null,
  updated_at  timestamptz not null default now()
);

alter table public.groups   enable row level security;
alter table public.profiles enable row level security;
alter table public.plans    enable row level security;

-- ---------- helper ----------

-- The signed-in person's group. SECURITY DEFINER so policies can use it without recursion.
create or replace function public.my_group_id()
returns uuid
language sql stable security definer
set search_path = public
as $$
  select group_id from public.profiles where id = auth.uid()
$$;

-- ---------- access rules ----------

-- Plans: private to their owner.
create policy "Own plan" on public.plans
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Profiles: you see yourself and the people in your group; you only change yourself.
create policy "Read self and group" on public.profiles
  for select to authenticated
  using (id = auth.uid() or (group_id is not null and group_id = public.my_group_id()));

create policy "Update self" on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Joining and leaving a group only happens through the functions below,
-- so group_id cannot be written directly.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (display_name, summary, studying, updated_at) on public.profiles to authenticated;

-- Groups: members can see their group and change its name and together-night settings.
create policy "Members read group" on public.groups
  for select to authenticated
  using (id = public.my_group_id());

create policy "Members update group" on public.groups
  for update to authenticated
  using (id = public.my_group_id())
  with check (id = public.my_group_id());

revoke insert, update, delete on public.groups from anon, authenticated;
grant update (name, settings) on public.groups to authenticated;

-- ---------- new accounts get a profile automatically ----------

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), split_part(new.email, '@', 1), 'Me'), 40)
  );
  return new;
end
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- group functions (called from the app) ----------

create or replace function public.create_group(p_name text, p_settings jsonb default '{}'::jsonb)
returns public.groups
language plpgsql security definer
set search_path = public
as $$
declare
  g public.groups;
  c text;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  loop
    -- 6 characters, no look-alikes (no 0/O, 1/I/L)
    select string_agg(substr('ABCDEFGHJKMNPQRSTUVWXYZ23456789', 1 + floor(random() * 31)::int, 1), '')
      into c from generate_series(1, 6);
    exit when not exists (select 1 from public.groups where code = c);
  end loop;
  insert into public.groups (name, code, settings, created_by)
  values (coalesce(nullif(left(trim(p_name), 60), ''), 'Study group'), c, coalesce(p_settings, '{}'::jsonb), auth.uid())
  returning * into g;
  perform public.leave_group();
  update public.profiles set group_id = g.id, updated_at = now() where id = auth.uid();
  return g;
end
$$;

create or replace function public.join_group(p_code text)
returns public.groups
language plpgsql security definer
set search_path = public
as $$
declare
  g public.groups;
begin
  if auth.uid() is null then
    raise exception 'Not signed in';
  end if;
  select * into g from public.groups where code = upper(trim(p_code));
  if not found then
    raise exception 'No group with that code';
  end if;
  if (select count(*) from public.profiles where group_id = g.id and id <> auth.uid()) >= 8 then
    raise exception 'That group is full';
  end if;
  if public.my_group_id() is distinct from g.id then
    perform public.leave_group();
  end if;
  update public.profiles set group_id = g.id, updated_at = now() where id = auth.uid();
  return g;
end
$$;

create or replace function public.leave_group()
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  old uuid;
begin
  select group_id into old from public.profiles where id = auth.uid();
  update public.profiles set group_id = null, studying = null, summary = null, updated_at = now()
   where id = auth.uid();
  -- tidy up a group nobody is in any more
  if old is not null and not exists (select 1 from public.profiles where group_id = old) then
    delete from public.groups where id = old;
  end if;
end
$$;

revoke execute on function public.create_group(text, jsonb), public.join_group(text), public.leave_group(), public.my_group_id() from public, anon;
grant execute on function public.create_group(text, jsonb), public.join_group(text), public.leave_group(), public.my_group_id() to authenticated;

-- ---------- live updates ----------

-- Lets the app hear about a buddy's progress, group changes, and your own plan
-- changing on another device, without refreshing.
alter publication supabase_realtime add table public.profiles, public.groups, public.plans;
