-- Cadeautjes: gevers (Oma, Meter, …) met elk een eigen geheime link.
-- Op die link ziet de gever alleen wat aan hem/haar gevraagd is, per gezinslid, en kan aanduiden wat hij/zij koopt.
-- "Delen via link" is daarvoor niet nodig. Voer uit NA cadeautjes.sql en cadeautjes-ouders.sql.
-- Plak dit in Supabase: SQL Editor > New query > Run

create table if not exists cadeau_gevers (
  id uuid primary key default gen_random_uuid(),
  naam text not null check (char_length(naam) between 1 and 100),
  token text not null unique default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  aangemaakt timestamptz not null default now()
);
create unique index if not exists cadeau_gevers_naam_uniek on cadeau_gevers (lower(naam));
alter table cadeau_gevers enable row level security;
drop policy if exists "ouders beheren gevers" on cadeau_gevers;
create policy "ouders beheren gevers" on cadeau_gevers for all to authenticated using (is_ouder()) with check (is_ouder());

alter table cadeau_ouders add column if not exists gever_id uuid references cadeau_gevers(id) on delete set null;

-- Bestaande vrije tekst "gevraagd aan" één keer omzetten naar gevers (hoofdletters/spaties tellen niet)
insert into cadeau_gevers (naam)
select distinct on (lower(trim(gevraagd_aan))) trim(gevraagd_aan)
from cadeau_ouders where coalesce(trim(gevraagd_aan), '') <> ''
on conflict do nothing;
update cadeau_ouders o set gever_id = g.id
from cadeau_gevers g
where o.gever_id is null and lower(trim(o.gevraagd_aan)) = lower(g.naam);

-- Openbare functies voor de gever-link (geen account nodig; de token is het geheim)
create or replace function cadeau_gever_info(p_token text)
returns table (naam text) language sql security definer set search_path = public stable as $$
  select g.naam from cadeau_gevers g where g.token = p_token $$;

create or replace function cadeau_gever_lijst(p_token text)
returns table (id uuid, titel text, link text, prijs_van numeric, prijs_tot numeric, door_naam text, voor_naam text, voor_emoji text)
language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, i.prijs_van, i.prijs_tot, c.door_naam,
         coalesce(ou.naam, k.naam, 'Iemand'), coalesce(ou.emoji, k.emoji, '🎁')
  from cadeau_gevers g
  join cadeau_ouders o on o.gever_id = g.id
  join cadeau_items i on i.id = o.item_id
  left join ouders ou on ou.user_id = i.voor_user
  left join kinderen k on k.user_id = i.voor_user
  left join cadeau_claims c on c.item_id = i.id
  where g.token = p_token and (k.id is null or k.test_voor is null)
  order by coalesce(ou.naam, k.naam), i.aangemaakt $$;

create or replace function cadeau_gever_claim(p_token text, p_item uuid, p_naam text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if char_length(trim(p_naam)) not between 1 and 40 then return false; end if;
  if not exists (select 1 from cadeau_gevers g join cadeau_ouders o on o.gever_id = g.id
                 where g.token = p_token and o.item_id = p_item) then return false; end if;
  insert into cadeau_claims (item_id, door_user, door_naam) values (p_item, null, trim(p_naam)) on conflict do nothing;
  return found;
end $$;

create or replace function cadeau_gever_unclaim(p_token text, p_item uuid, p_naam text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  delete from cadeau_claims c using cadeau_gevers g, cadeau_ouders o
  where g.token = p_token and o.gever_id = g.id and o.item_id = p_item
    and c.item_id = p_item and c.door_user is null and c.door_naam = trim(p_naam);
  return found;
end $$;

grant execute on function cadeau_gever_info(text), cadeau_gever_lijst(text),
  cadeau_gever_claim(text, uuid, text), cadeau_gever_unclaim(text, uuid, text) to anon, authenticated;
