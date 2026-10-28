-- Voer uit NA schema.sql en kindlogin.sql (gebruikt is_ouder()).

create table categorieen (
  id uuid primary key default gen_random_uuid(),
  naam text not null unique,
  standaard_volgorde int not null
);
create table producten (
  id uuid primary key default gen_random_uuid(),
  naam text not null,
  categorie_id uuid not null references categorieen(id) on delete cascade
);
create unique index producten_naam_uniek on producten (lower(naam));
create table lijst (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null unique references producten(id) on delete cascade,
  afgevinkt boolean not null default false,
  toegevoegd timestamptz not null default now()
);
create table winkels (
  id uuid primary key default gen_random_uuid(),
  naam text not null
);
create table winkel_volgorde (
  winkel_id uuid not null references winkels(id) on delete cascade,
  categorie_id uuid not null references categorieen(id) on delete cascade,
  positie int not null,
  primary key (winkel_id, categorie_id)
);

alter table categorieen enable row level security;
alter table producten enable row level security;
alter table lijst enable row level security;
alter table winkels enable row level security;
alter table winkel_volgorde enable row level security;

-- Iedereen die ingelogd is (ouders en kinderen): lezen, en producten/lijst aanpassen
create policy "lezen categorieen" on categorieen for select to authenticated using (true);
create policy "lezen winkels" on winkels for select to authenticated using (true);
create policy "lezen volgorde" on winkel_volgorde for select to authenticated using (true);
create policy "lezen producten" on producten for select to authenticated using (true);
create policy "toevoegen producten" on producten for insert to authenticated with check (true);
create policy "lijst beheren" on lijst for all to authenticated using (true) with check (true);
-- Alleen ouders: categorieën, winkels, volgorde, producten wijzigen of verwijderen
create policy "ouder categorieen" on categorieen for all to authenticated using (is_ouder()) with check (is_ouder());
create policy "ouder winkels" on winkels for all to authenticated using (is_ouder()) with check (is_ouder());
create policy "ouder volgorde" on winkel_volgorde for all to authenticated using (is_ouder()) with check (is_ouder());
create policy "ouder producten" on producten for update to authenticated using (is_ouder()) with check (is_ouder());
create policy "ouder producten wissen" on producten for delete to authenticated using (is_ouder());

-- Live synchronisatie tussen toestellen
alter publication supabase_realtime add table lijst;

insert into categorieen (naam, standaard_volgorde)
select naam, row_number() over () from unnest(array[
  'Verzorging','Huishouden','Blik & Bokalen','Sauzen, bloem & kruiden','Pasta/deegwaren','Zoet',
  'Brood & ontbijt','Beleg','Apero','Fruit','Groente','Verse kruiden','Noten en gedroogd fruit',
  'Vlees/veggie/vis','Zuivel','Drank','Diepvries','Andere']) as naam;

-- Een paar voorbeeldproducten; de rest groeit vanzelf in de app
insert into producten (naam, categorie_id)
select v.naam, c.id from (values
  ('Tandpasta','Verzorging'),('Shampoo','Verzorging'),('Afwasmiddel','Huishouden'),('Toiletpapier','Huishouden'),
  ('Tomatenblokjes','Blik & Bokalen'),('Maïs','Blik & Bokalen'),('Bloem','Sauzen, bloem & kruiden'),('Pesto','Sauzen, bloem & kruiden'),
  ('Spaghetti','Pasta/deegwaren'),('Rijst','Pasta/deegwaren'),('Chocolade','Zoet'),('Koekjes','Zoet'),
  ('Brood','Brood & ontbijt'),('Cornflakes','Brood & ontbijt'),('Kaas','Beleg'),('Choco','Beleg'),
  ('Chips','Apero'),('Olijven','Apero'),('Appels','Fruit'),('Bananen','Fruit'),
  ('Tomaten','Groente'),('Wortelen','Groente'),('Peterselie','Verse kruiden'),('Basilicum','Verse kruiden'),
  ('Amandelen','Noten en gedroogd fruit'),('Rozijnen','Noten en gedroogd fruit'),('Kipfilet','Vlees/veggie/vis'),('Zalm','Vlees/veggie/vis'),
  ('Melk','Zuivel'),('Yoghurt','Zuivel'),('Water','Drank'),('Appelsap','Drank'),('Ijs','Diepvries'),('Diepvriesgroenten','Diepvries')
) as v(naam, cat) join categorieen c on c.naam = v.cat;
