-- =====================================================================
-- BLU PADEL — estrutura do Supabase para o painel de torneios
-- Rode tudo no Supabase: SQL Editor > New query > colar > Run.
-- Pode rodar de novo sem problema (é idempotente).
-- =====================================================================

-- ---------- Tabela de torneios ----------
create table if not exists public.tournaments (
  id               uuid primary key default gen_random_uuid(),
  title            text not null check (char_length(title) between 1 and 80),
  stage            text check (stage is null or char_length(stage) <= 60),
  cover_url        text not null check (char_length(cover_url) <= 500),
  date_start       date not null,
  date_end         date not null,
  price            numeric(10,2) check (price is null or (price >= 0 and price <= 100000)),
  price_note       text check (price_note is null or char_length(price_note) <= 90),
  categories       text check (categories is null or char_length(categories) <= 240),
  registration_url text check (registration_url is null or registration_url = '' or registration_url ~* '^https?://'),
  published        boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint tournaments_dates_ok check (date_end >= date_start)
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists tournaments_touch on public.tournaments;
create trigger tournaments_touch before update on public.tournaments
for each row execute function public.touch_updated_at();

-- ---------- Quem pode administrar ----------
-- Só usuários listados aqui conseguem criar/editar/excluir torneios,
-- mesmo que alguém consiga criar uma conta no Auth.
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admins enable row level security;  -- sem políticas: ninguém lê pela API

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- ---------- Segurança da tabela (RLS) ----------
alter table public.tournaments enable row level security;

drop policy if exists "site le publicados"   on public.tournaments;
drop policy if exists "admin le tudo"        on public.tournaments;
drop policy if exists "admin cria"           on public.tournaments;
drop policy if exists "admin edita"          on public.tournaments;
drop policy if exists "admin exclui"         on public.tournaments;

create policy "site le publicados" on public.tournaments
  for select to anon, authenticated using (published = true);
create policy "admin le tudo" on public.tournaments
  for select to authenticated using (public.is_admin());
create policy "admin cria" on public.tournaments
  for insert to authenticated with check (public.is_admin());
create policy "admin edita" on public.tournaments
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin exclui" on public.tournaments
  for delete to authenticated using (public.is_admin());

-- ---------- Storage: capas dos torneios ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('torneios', 'torneios', true, 8388608, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "torneios admin envia"  on storage.objects;
drop policy if exists "torneios admin troca"  on storage.objects;
drop policy if exists "torneios admin apaga"  on storage.objects;

create policy "torneios admin envia" on storage.objects
  for insert to authenticated with check (bucket_id = 'torneios' and public.is_admin());
create policy "torneios admin troca" on storage.objects
  for update to authenticated using (bucket_id = 'torneios' and public.is_admin());
create policy "torneios admin apaga" on storage.objects
  for delete to authenticated using (bucket_id = 'torneios' and public.is_admin());

-- ---------- Circuitos já realizados (cartazes que já estão no site) ----------
insert into public.tournaments (title, stage, cover_url, date_start, date_end, price, price_note, categories, published)
select * from (values
  ('Circuito Blu Padel', 'Etapa final', 'assets/img/circuito-blu-padel.webp', date '2025-11-27', date '2025-11-29', 160::numeric, null::text,
   'Masculina 2ª a 6ª e iniciante · Feminina 3ª a 6ª e iniciante', true),
  ('Circuito Blu Padel', '2ª etapa', 'assets/img/circuito-2etapa-a.webp', date '2026-07-03', date '2026-07-05', 160::numeric, 'R$ 150 para o Clube Padel Delas',
   'Masculino e Feminino · 3ª a 7ª + 2ª Masc. e Infantil + A, B, C e D mista', true),
  ('Circuito Blu Padel', '2ª etapa · Beach Tennis', 'assets/img/circuito-2etapa-b.webp', date '2026-07-03', date '2026-07-05', 160::numeric, null::text,
   'Masculino e Feminino · 3ª a 7ª + 2ª Masculina e Infantil + A, B, C e D mista', true)
) as v(title, stage, cover_url, date_start, date_end, price, price_note, categories, published)
where not exists (select 1 from public.tournaments);

-- =====================================================================
-- DEPOIS de criar o usuário do painel em Authentication > Users
-- (Add user > e-mail bluepadel@blupadel.com.br, marque "Auto Confirm User"),
-- rode a linha abaixo para dar permissão de administrador:
--
-- insert into public.admins (user_id)
-- select id from auth.users where email = 'bluepadel@blupadel.com.br'
-- on conflict do nothing;
-- =====================================================================
