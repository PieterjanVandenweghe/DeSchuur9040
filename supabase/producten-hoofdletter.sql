-- Bestaande producten met een hoofdletter laten beginnen ("uien" -> "Uien", "ijsblokjes" -> "IJsblokjes").
-- De rest van de naam blijft ongewijzigd. Plak dit in Supabase: SQL Editor > New query > Run.
-- Veilig: de unieke index op lower(naam) verandert niet, dus er ontstaan geen dubbels.

-- 1) Eerst bekijken wat er zou veranderen (alleen lezen):
select naam as nu,
       case when naam ~* '^ij' then 'IJ' || substr(naam, 3) else upper(left(naam, 1)) || substr(naam, 2) end as wordt
from producten
where naam <> case when naam ~* '^ij' then 'IJ' || substr(naam, 3) else upper(left(naam, 1)) || substr(naam, 2) end
order by naam;

-- 2) Ziet dat er goed uit? Voer dan dit uit:
-- update producten
-- set naam = case when naam ~* '^ij' then 'IJ' || substr(naam, 3) else upper(left(naam, 1)) || substr(naam, 2) end
-- where naam <> case when naam ~* '^ij' then 'IJ' || substr(naam, 3) else upper(left(naam, 1)) || substr(naam, 2) end;
