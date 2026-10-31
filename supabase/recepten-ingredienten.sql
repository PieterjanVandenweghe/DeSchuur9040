-- Ingrediënten bij recepten. Voer uit NA menu.sql (en boodschappen.sql / uitbreidingen.sql, want ze verwijzen naar de producten).

create table recept_ingredienten (
  id uuid primary key default gen_random_uuid(),
  recept_id uuid not null references recepten(id) on delete cascade,
  product_id uuid not null references producten(id) on delete cascade,
  hoeveelheid numeric check (hoeveelheid > 0),          -- leeg = geen hoeveelheid (bv. zout)
  eenheid text not null default 'st' check (eenheid in ('st', 'g')),
  unique (recept_id, product_id)
);
alter table recept_ingredienten enable row level security;
create policy "ingredienten lezen" on recept_ingredienten for select to authenticated
  using ((select auth.uid()) is not null);
create policy "ingredienten schrijven" on recept_ingredienten for all to authenticated
  using ((select auth.uid()) is not null) with check ((select auth.uid()) is not null);

-- Optioneel: oude menu's ook automatisch in de database opruimen (de app doet dit al bij het openen).
-- Vereist de extensie pg_cron (Database > Extensions). Houdt de vorige 2 weken bij.
-- select cron.schedule('menu-opruimen', '0 3 * * *',
--   $$ delete from menu_dagen where week < (date_trunc('week', current_date)::date - 14) $$);
