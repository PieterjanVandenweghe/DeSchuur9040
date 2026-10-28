-- Cadeautjes-module. Voer uit NA kindlogin.sql (gebruikt is_ouder()).

-- Ingelogde gezinsleden mogen elkaars naam zien (nodig voor de lijstjes per persoon)
create policy "ouders lezen ingelogd" on ouders for select to authenticated using (true);

create table cadeau_items (
  id uuid primary key default gen_random_uuid(),
  voor_user uuid not null references auth.users(id) on delete cascade,
  titel text not null check (char_length(titel) between 1 and 200),
  link text check (link is null or char_length(link) <= 1000),
  toegevoegd_door uuid not null default auth.uid() references auth.users(id) on delete cascade,
  aangemaakt timestamptz not null default now()
);
create table cadeau_claims (
  item_id uuid primary key references cadeau_items(id) on delete cascade,
  door_user uuid default auth.uid() references auth.users(id) on delete set null,
  door_naam text not null check (char_length(door_naam) between 1 and 40),
  aangemaakt timestamptz not null default now()
);
create table cadeau_delen (
  id uuid primary key default gen_random_uuid(),
  voor_user uuid not null references auth.users(id) on delete cascade,
  token text not null unique default replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  aangemaakt timestamptz not null default now()
);
alter table cadeau_items enable row level security;
alter table cadeau_claims enable row level security;
alter table cadeau_delen enable row level security;

-- Cadeautjes: iedereen ingelogd leest en voegt toe; wijzigen of wissen mag de maker of een ouder
create policy "items lezen" on cadeau_items for select to authenticated using (true);
create policy "items toevoegen" on cadeau_items for insert to authenticated with check (toegevoegd_door = auth.uid());
create policy "items wijzigen" on cadeau_items for update to authenticated
  using (toegevoegd_door = auth.uid() or is_ouder()) with check (toegevoegd_door = auth.uid() or is_ouder());
create policy "items wissen" on cadeau_items for delete to authenticated using (toegevoegd_door = auth.uid() or is_ouder());

-- "Ik koop dit": NIET zichtbaar voor de eigenaar van het lijstje (verrassing!) en niet te claimen voor jezelf
create policy "claims lezen" on cadeau_claims for select to authenticated
  using (exists (select 1 from cadeau_items i where i.id = item_id and i.voor_user <> auth.uid()));
create policy "claims toevoegen" on cadeau_claims for insert to authenticated
  with check (door_user = auth.uid() and exists (select 1 from cadeau_items i where i.id = item_id and i.voor_user <> auth.uid()));
create policy "claims wissen" on cadeau_claims for delete to authenticated using (door_user = auth.uid() or is_ouder());

-- Deellinks: alleen ouders beheren ze
create policy "delen ouder" on cadeau_delen for all to authenticated using (is_ouder()) with check (is_ouder());

-- Functies voor mensen zonder account die een geheime deellink hebben (de token in de link is de sleutel)
create or replace function cadeau_deel_info(p_token text)
returns table (naam text, emoji text) language sql security definer set search_path = public stable as $$
  select coalesce(o.naam, k.naam, 'Iemand'), coalesce(o.emoji, k.emoji, '🎁')
  from cadeau_delen d left join ouders o on o.user_id = d.voor_user left join kinderen k on k.user_id = d.voor_user
  where d.token = p_token $$;

create or replace function cadeau_deel_lijst(p_token text)
returns table (id uuid, titel text, link text, door_naam text) language sql security definer set search_path = public stable as $$
  select i.id, i.titel, i.link, c.door_naam
  from cadeau_delen d join cadeau_items i on i.voor_user = d.voor_user left join cadeau_claims c on c.item_id = i.id
  where d.token = p_token order by i.aangemaakt $$;

create or replace function cadeau_deel_claim(p_token text, p_item uuid, p_naam text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if char_length(trim(p_naam)) not between 1 and 40 then return false; end if;
  if not exists (select 1 from cadeau_delen d join cadeau_items i on i.voor_user = d.voor_user
                 where d.token = p_token and i.id = p_item) then return false; end if;
  insert into cadeau_claims (item_id, door_user, door_naam) values (p_item, null, trim(p_naam)) on conflict do nothing;
  return found;
end $$;

create or replace function cadeau_deel_unclaim(p_token text, p_item uuid, p_naam text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  delete from cadeau_claims c using cadeau_delen d, cadeau_items i
  where d.token = p_token and i.id = p_item and i.voor_user = d.voor_user
    and c.item_id = i.id and c.door_user is null and c.door_naam = trim(p_naam);
  return found;
end $$;

grant execute on function cadeau_deel_info(text), cadeau_deel_lijst(text),
  cadeau_deel_claim(text, uuid, text), cadeau_deel_unclaim(text, uuid, text) to anon, authenticated;
