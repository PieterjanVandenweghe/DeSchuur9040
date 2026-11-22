-- Cadeautjes: fotootje van de productpagina. Alleen de link naar de foto wordt bewaard (geen opslag nodig).
-- Voer uit NA cadeautjes-gevers.sql. Plak dit in Supabase: SQL Editor > New query > Run

alter table cadeau_items add column if not exists foto_url text
  check (foto_url is null or (char_length(foto_url) <= 2000 and foto_url ~ '^https?://'));

-- De deellijsten geven nu ook de foto mee (ander resultaattype: eerst verwijderen)
drop function if exists cadeau_deel_lijst(text);
create function cadeau_deel_lijst(p_token text)
returns table (id uuid, titel text, link text, prijs_van numeric, prijs_tot numeric, door_naam text, foto_url text)
language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, i.prijs_van, i.prijs_tot, c.door_naam, i.foto_url
  from cadeau_delen d
  join cadeau_items i on i.voor_user = d.voor_user
  join cadeau_ouders o on o.item_id = i.id and o.gedeeld
  left join cadeau_claims c on c.item_id = i.id
  where d.token = p_token order by i.aangemaakt $$;

drop function if exists cadeau_gever_lijst(text);
create function cadeau_gever_lijst(p_token text)
returns table (id uuid, titel text, link text, prijs_van numeric, prijs_tot numeric, door_naam text, voor_naam text, voor_emoji text, foto_url text)
language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, i.prijs_van, i.prijs_tot, c.door_naam,
         coalesce(ou.naam, k.naam, 'Iemand'), coalesce(ou.emoji, k.emoji, '🎁'), i.foto_url
  from cadeau_gevers g
  join cadeau_ouders o on o.gever_id = g.id
  join cadeau_items i on i.id = o.item_id
  left join ouders ou on ou.user_id = i.voor_user
  left join kinderen k on k.user_id = i.voor_user
  left join cadeau_claims c on c.item_id = i.id
  where g.token = p_token and (k.id is null or k.test_voor is null)
  order by coalesce(ou.naam, k.naam), i.aangemaakt $$;

grant execute on function cadeau_deel_lijst(text), cadeau_gever_lijst(text) to anon, authenticated;
