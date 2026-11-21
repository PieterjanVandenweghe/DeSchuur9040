-- Recepten mogen gewijzigd worden (bv. voor hoeveel personen) door een ouder of wie het recept toevoegde.
-- Plak dit in Supabase: SQL Editor > New query > Run
drop policy if exists "recepten wijzigen" on recepten;
create policy "recepten wijzigen" on recepten for update to authenticated
  using (is_ouder() or toegevoegd_door = auth.uid())
  with check (is_ouder() or toegevoegd_door = auth.uid());
