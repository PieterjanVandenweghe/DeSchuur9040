-- Voer dit uit NA schema.sql (SQL Editor > New query > Run).
-- Doel: kinderen kunnen inloggen met een code en een joker AANVRAGEN;
-- alleen een ouder kan dagen beoordelen en aanvragen goedkeuren.

alter table kinderen add column if not exists login_email text;
alter table kinderen add column if not exists user_id uuid references auth.users(id) on delete set null;

create table if not exists ouders (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table ouders enable row level security;
create policy "ouder ziet eigen rij" on ouders for select to authenticated using (user_id = auth.uid());

create or replace function is_ouder() returns boolean
language sql security definer set search_path = public stable
as $$ select exists (select 1 from ouders where user_id = auth.uid()) $$;

-- Schrijfrechten alleen nog voor ouders (kinderaccounts zijn ook 'authenticated')
drop policy if exists "ouder schrijft kinderen" on kinderen;
drop policy if exists "ouder schrijft dagen" on dagen;
create policy "ouder schrijft kinderen" on kinderen for all to authenticated using (is_ouder()) with check (is_ouder());
create policy "ouder schrijft dagen" on dagen for all to authenticated using (is_ouder()) with check (is_ouder());

create table if not exists jokeraanvragen (
  id uuid primary key default gen_random_uuid(),
  kind_id uuid not null references kinderen(id) on delete cascade,
  datum date not null,
  status text not null default 'open' check (status in ('open', 'goedgekeurd', 'afgewezen')),
  aangemaakt timestamptz not null default now(),
  unique (kind_id, datum)
);
alter table jokeraanvragen enable row level security;

create policy "ouder beheert aanvragen" on jokeraanvragen for all to authenticated
  using (is_ouder()) with check (is_ouder());
create policy "kind ziet eigen aanvragen" on jokeraanvragen for select to authenticated
  using (kind_id in (select id from kinderen where user_id = auth.uid()));
create policy "kind vraagt joker aan" on jokeraanvragen for insert to authenticated
  with check (
    status = 'open'
    and kind_id in (select id from kinderen where user_id = auth.uid())
    and exists (select 1 from dagen d where d.kind_id = jokeraanvragen.kind_id
                and d.datum = jokeraanvragen.datum and d.status = 'rommel')
  );

-- STAP A: jezelf als ouder registreren (vervang het e-mailadres door jouw inlog-adres)
insert into ouders (user_id) select id from auth.users where email = 'JOUW@EMAILADRES' on conflict do nothing;

-- STAP B: per kind (nadat je het account in Authentication > Users hebt aangemaakt)
-- update kinderen set login_email = 'emma@kinderen.example.com' where volgorde = 1;
-- update kinderen set login_email = 'lotte@kinderen.example.com' where volgorde = 2;
-- update kinderen k set user_id = u.id from auth.users u where u.email = k.login_email;
