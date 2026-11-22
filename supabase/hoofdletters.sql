-- Bestaande namen laten beginnen met een hoofdletter ("moetje" -> "Moetje", "ijs" -> "IJs").
-- Geldt voor gevers, cadeautjes, recepten, winkels en categorieën (producten: zie producten-hoofdletter.sql).
-- Nieuwe namen krijgen de hoofdletter al automatisch in de app.
-- Plak dit in Supabase: SQL Editor > New query > Run

create or replace function hoofdletter(t text) returns text language sql immutable as $$
  select case when t ~* '^ij' then 'IJ' || substr(t, 3) else upper(left(t, 1)) || substr(t, 2) end $$;

-- 1) Eerst bekijken wat er zou veranderen (alleen lezen):
select 'gever' as soort, naam as nu, hoofdletter(naam) as wordt from cadeau_gevers where naam <> hoofdletter(naam)
union all select 'cadeautje', titel, hoofdletter(titel) from cadeau_items where titel <> hoofdletter(titel)
union all select 'recept', titel, hoofdletter(titel) from recepten where titel <> hoofdletter(titel)
union all select 'winkel', naam, hoofdletter(naam) from winkels where naam <> hoofdletter(naam)
union all select 'categorie', naam, hoofdletter(naam) from categorieen where naam <> hoofdletter(naam)
order by 1, 2;

-- 2) Ziet dat er goed uit? Haal de -- weg voor de regels hieronder en voer opnieuw uit:
-- update cadeau_gevers set naam = hoofdletter(naam) where naam <> hoofdletter(naam);
-- update cadeau_items set titel = hoofdletter(titel) where titel <> hoofdletter(titel);
-- update recepten set titel = hoofdletter(titel) where titel <> hoofdletter(titel);
-- update winkels set naam = hoofdletter(naam) where naam <> hoofdletter(naam);
-- update categorieen set naam = hoofdletter(naam) where naam <> hoofdletter(naam);
