-- Alleen voor ouders: per cadeautje aanduiden of het via een deellink gedeeld wordt, en een eigen label
-- "gevraagd aan". Kinderen kunnen deze tabel niet lezen, dus het blijft een verrassing.
-- Voer uit NA cadeautjes.sql (en cadeautjes-prijs.sql als je die al had).

create table if not exists cadeau_ouders (
  item_id uuid primary key references cadeau_items(id) on delete cascade,
  gedeeld boolean not null default false,
  gevraagd_aan text check (gevraagd_aan is null or char_length(gevraagd_aan) <= 100)
);
alter table cadeau_ouders enable row level security;
drop policy if exists "ouders beheren cadeau-instellingen" on cadeau_ouders;
create policy "ouders beheren cadeau-instellingen" on cadeau_ouders for all to authenticated
  using (is_ouder()) with check (is_ouder());

-- Via een deellink zie en claim je alleen cadeautjes die als "gedeeld" zijn aangeduid
create or replace function cadeau_deel_lijst(p_token text)
returns table (id uuid, titel text, link text, prijs_van numeric, prijs_tot numeric, door_naam text)
language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, i.prijs_van, i.prijs_tot, c.door_naam
  from cadeau_delen d
  join cadeau_items i on i.voor_user = d.voor_user
  join cadeau_ouders o on o.item_id = i.id and o.gedeeld
  left join cadeau_claims c on c.item_id = i.id
  where d.token = p_token order by i.aangemaakt $$;

create or replace function cadeau_deel_claim(p_token text, p_item uuid, p_naam text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if char_length(trim(p_naam)) not between 1 and 40 then return false; end if;
  if not exists (select 1 from cadeau_delen d
                 join cadeau_items i on i.voor_user = d.voor_user
                 join cadeau_ouders o on o.item_id = i.id and o.gedeeld
                 where d.token = p_token and i.id = p_item) then return false; end if;
  insert into cadeau_claims (item_id, door_user, door_naam) values (p_item, null, trim(p_naam)) on conflict do nothing;
  return found;
end $$;

grant execute on function cadeau_deel_lijst(text), cadeau_deel_claim(text, uuid, text) to anon, authenticated;

-- Bestaande deellinks tonen vanaf nu NIETS totdat je cadeautjes aanvinkt. Wil je alles wat er al staat meteen delen?
-- Haal dan de commentaartekens weg en voer dit uit:
-- insert into cadeau_ouders (item_id, gedeeld) select id, true from cadeau_items
--   on conflict (item_id) do update set gedeeld = true;
