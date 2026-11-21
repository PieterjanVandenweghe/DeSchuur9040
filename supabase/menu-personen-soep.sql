-- Menu: soep van de week, standaard aantal personen en per dag overschrijven.
-- Plak dit in Supabase: SQL Editor > New query > Run

-- Algemene instellingen voor het gezin (iedereen leest, ouders wijzigen)
create table if not exists instellingen (
  sleutel text primary key check (char_length(sleutel) <= 50),
  waarde jsonb not null
);
alter table instellingen enable row level security;
create policy "instellingen lezen" on instellingen for select to authenticated using (true);
create policy "instellingen beheren" on instellingen for all to authenticated using (is_ouder()) with check (is_ouder());
insert into instellingen (sleutel, waarde) values ('standaard_personen', '4') on conflict do nothing;

-- Voor hoeveel personen een recept geschreven is (standaard 4)
alter table recepten add column if not exists personen int not null default 4 check (personen between 1 and 30);

-- Per dag afwijken (leeg = standaard), en dag 7 = soep van de week
alter table menu_dagen add column if not exists personen int check (personen between 1 and 30);
alter table menu_dagen drop constraint if exists menu_dagen_dag_check;
alter table menu_dagen add constraint menu_dagen_dag_check check (dag between 0 and 7);
