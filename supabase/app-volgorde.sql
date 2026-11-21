-- Eigen volgorde van de app-tegels op de thuispagina, per persoon.
-- Plak dit in Supabase: SQL Editor > New query > Run
create table if not exists app_volgorde (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  apps text[] not null default '{}',
  check (cardinality(apps) <= 50)
);
alter table app_volgorde enable row level security;
create policy "eigen volgorde" on app_volgorde for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
