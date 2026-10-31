-- Menu & recepten. Voer uit NA uitbreidingen2.sql en drama.sql (gebruikt app_verbergen en is_ouder()).

create table recepten (
  id uuid primary key default gen_random_uuid(),
  titel text not null check (char_length(titel) between 1 and 200),
  link text check (link is null or char_length(link) <= 1000),
  notitie text check (notitie is null or char_length(notitie) <= 500),
  toegevoegd_door uuid default auth.uid() references auth.users(id) on delete set null,
  aangemaakt timestamptz not null default now()
);
create table menu_dagen (
  week date not null,                                   -- de maandag van die week
  dag int not null check (dag between 0 and 6),         -- 0 = maandag ... 6 = zondag
  tekst text check (tekst is null or char_length(tekst) <= 300),
  link text check (link is null or char_length(link) <= 1000),
  recept_id uuid references recepten(id) on delete set null,
  primary key (week, dag)
);
alter table recepten enable row level security;
alter table menu_dagen enable row level security;

-- Iedereen die ingelogd is: lezen en aanvullen. Recepten wissen: een ouder of wie het toevoegde.
create policy "recepten lezen" on recepten for select to authenticated using (true);
create policy "recepten toevoegen" on recepten for insert to authenticated with check (true);
create policy "recepten wissen" on recepten for delete to authenticated using (is_ouder() or toegevoegd_door = auth.uid());
create policy "menu beheren" on menu_dagen for all to authenticated using (true) with check (true);

-- De app mag verborgen worden via "Wie ziet welke apps?"
alter table app_verbergen drop constraint if exists app_verbergen_app_check;
alter table app_verbergen add constraint app_verbergen_app_check
  check (app in ('opruim', 'boodschappen', 'toilet', 'cadeautjes', 'drama', 'menu'));
