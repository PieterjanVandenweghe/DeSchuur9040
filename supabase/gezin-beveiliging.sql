-- Extra beveiliging: alleen gezinsleden (gekoppelde ouders en kinderen) mogen iets lezen of schrijven.
-- Zo blijft alles dicht, ook als "Allow new users to sign up" ooit per ongeluk weer aan staat:
-- een los account zonder koppeling ziet en wijzigt dan niets.
-- Veilig om opnieuw uit te voeren. Plak dit in Supabase: SQL Editor > New query > Run

create or replace function is_gezin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from ouders where user_id = auth.uid())
      or exists (select 1 from kinderen where user_id = auth.uid()) $$;
grant execute on function is_gezin() to authenticated;

-- 1) Alle regels die nu "elke ingelogde gebruiker" toelaten, krijgen is_gezin() in de plaats.
--    We zoeken ze op in de database zelf, zodat ook oudere varianten meegenomen worden.
do $$
declare p record; nieuw text;
begin
  for p in
    select tablename, policyname, cmd, qual, with_check from pg_policies
    where schemaname = 'public' and 'authenticated' = any(roles)
      and (coalesce(qual, '') in ('true', '(( SELECT auth.uid() AS uid) IS NOT NULL)', '(auth.uid() IS NOT NULL)')
        or coalesce(with_check, '') in ('true', '(( SELECT auth.uid() AS uid) IS NOT NULL)', '(auth.uid() IS NOT NULL)'))
  loop
    nieuw := case p.cmd
      when 'SELECT' then 'using (is_gezin())'
      when 'DELETE' then 'using (is_gezin())'
      when 'INSERT' then 'with check (is_gezin())'
      else 'using (is_gezin()) with check (is_gezin())' end;
    execute format('alter policy %I on %I %s', p.policyname, p.tablename, nieuw);
    raise notice 'Aangepast: % op %', p.policyname, p.tablename;
  end loop;
end $$;

-- 2) Regels die naar de eigen gebruiker kijken, maar een los account toch iets zouden laten doen
alter policy "lezen kinderen" on kinderen
  using (is_gezin() and (test_voor is null or test_voor = auth.uid() or user_id = auth.uid()));
alter policy "claims lezen" on cadeau_claims
  using (is_gezin() and exists (select 1 from cadeau_items i where i.id = item_id and i.voor_user <> auth.uid()));
alter policy "claims toevoegen" on cadeau_claims
  with check (is_gezin() and door_user = auth.uid() and exists (select 1 from cadeau_items i where i.id = item_id and i.voor_user <> auth.uid()));
alter policy "items toevoegen" on cadeau_items with check (is_gezin() and toegevoegd_door = auth.uid());

-- 3) Controle: deze regels laten nog iedereen toe die ingelogd is (hoort leeg te zijn)
select tablename, policyname, cmd, qual, with_check from pg_policies
where schemaname = 'public' and 'authenticated' = any(roles)
  and (coalesce(qual, '') = 'true' or coalesce(with_check, '') = 'true');
