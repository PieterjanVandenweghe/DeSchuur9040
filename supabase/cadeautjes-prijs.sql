-- Prijsrange bij cadeautjes. Voer dit uit als je cadeautjes.sql al eerder had uitgevoerd.

alter table cadeau_items add column if not exists prijs_van numeric check (prijs_van >= 0);
alter table cadeau_items add column if not exists prijs_tot numeric check (prijs_tot >= 0);
alter table cadeau_items drop constraint if exists cadeau_items_prijsbereik;
alter table cadeau_items add constraint cadeau_items_prijsbereik
  check (prijs_van is null or prijs_tot is null or prijs_tot >= prijs_van);

-- De functie voor de deellink moet de prijs ook teruggeven (nieuwe kolommen = functie opnieuw maken)
drop function if exists cadeau_deel_lijst(text);
create function cadeau_deel_lijst(p_token text)
returns table (id uuid, titel text, link text, prijs_van numeric, prijs_tot numeric, door_naam text)
language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, i.prijs_van, i.prijs_tot, c.door_naam
  from cadeau_delen d join cadeau_items i on i.voor_user = d.voor_user left join cadeau_claims c on c.item_id = i.id
  where d.token = p_token order by i.aangemaakt $$;
grant execute on function cadeau_deel_lijst(text) to anon, authenticated;
