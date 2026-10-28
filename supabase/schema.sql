-- Plak dit in Supabase: SQL Editor > New query > Run

create table kinderen (
  id uuid primary key default gen_random_uuid(),
  naam text not null,
  emoji text not null default '🦄',
  volgorde int not null default 0,
  beperking text not null default 'Schermtijd',   -- wat er minder wordt bij rommel
  basis_minuten int not null default 60,
  straf_minuten int not null default 15
);

create table dagen (
  kind_id uuid not null references kinderen(id) on delete cascade,
  datum date not null,
  status text not null check (status in ('opgeruimd', 'rommel', 'joker')),
  primary key (kind_id, datum)
);

alter table kinderen enable row level security;
alter table dagen enable row level security;

-- Iedereen (ook de meisjes zonder login) mag lezen
create policy "lezen kinderen" on kinderen for select to anon, authenticated using (true);
create policy "lezen dagen" on dagen for select to anon, authenticated using (true);

-- Alleen een ingelogde ouder mag schrijven
create policy "ouder schrijft kinderen" on kinderen for all to authenticated using (true) with check (true);
create policy "ouder schrijft dagen" on dagen for all to authenticated using (true) with check (true);

-- Pas de namen en emoji's aan naar jullie dochters
insert into kinderen (naam, emoji, volgorde, beperking, basis_minuten, straf_minuten) values
  ('Dochter 1', '🦄', 1, 'Social media', 60, 15),
  ('Dochter 2', '🐙', 2, 'Schermtijd', 60, 15);
