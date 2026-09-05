-- ══════════════════════════════════════════════════════════════
-- Code Circadien · Olympe Athlétique — schéma Supabase
-- À exécuter une fois dans : Dashboard Supabase → SQL Editor → New query
-- ══════════════════════════════════════════════════════════════

-- 1) Profils utilisateurs (étend auth.users avec un rôle client/coach)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'client' check (role in ('client','coach')),
  prenom text,
  email text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- 2) Fonction utilitaire : l'utilisateur connecté est-il coach ?
--    security definer = contourne la RLS de "profiles" pour éviter
--    toute récursion de policy (pattern standard Supabase).
create or replace function public.is_coach()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'coach'
  );
$$;

-- 3) Policies "profiles"
drop policy if exists "profiles_self_select" on public.profiles;
create policy "profiles_self_select" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_self_update" on public.profiles;
create policy "profiles_self_update" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "profiles_self_insert" on public.profiles;
create policy "profiles_self_insert" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_coach_select_all" on public.profiles;
create policy "profiles_coach_select_all" on public.profiles
  for select using (public.is_coach());

-- 4) Bilans (un enregistrement JSON par client — mêmes données que
--    l'ancien localStorage : réponses, horaires, ajustement coach, mesures)
create table if not exists public.bilans (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.bilans enable row level security;

drop policy if exists "bilans_self_all" on public.bilans;
create policy "bilans_self_all" on public.bilans
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "bilans_coach_select" on public.bilans;
create policy "bilans_coach_select" on public.bilans
  for select using (public.is_coach());

drop policy if exists "bilans_coach_update" on public.bilans;
create policy "bilans_coach_update" on public.bilans
  for update using (public.is_coach());

-- 5) updated_at automatique
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists bilans_set_updated_at on public.bilans;
create trigger bilans_set_updated_at
  before update on public.bilans
  for each row execute function public.set_updated_at();

-- 6) Création automatique du profil à l'inscription (1er lien magique)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ══════════════════════════════════════════════════════════════
-- 7) Pour te transformer en coach : connecte-toi une première fois
--    sur le site avec ton email (ça crée automatiquement ta ligne
--    dans "profiles"), puis lance cette requête (adapte l'email) :
--
--    update public.profiles set role = 'coach' where email = 'olympeathletique@gmail.com';
-- ══════════════════════════════════════════════════════════════
