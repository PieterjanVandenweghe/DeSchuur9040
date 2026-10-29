-- Toilet per keer + wie ziet welke app. Voer uit NA uitbreidingen.sql en cadeautjes.sql.

-- 1. Toilet: elke keer is een eigen regel met een eigen score (hardheid 1-5, leeg = weet niet)
create table if not exists toilet_bezoeken (
  id uuid primary key default gen_random_uuid(),
  kind_id uuid not null references kinderen(id) on delete cascade,
  datum date not null,
  hardheid int check (hardheid between 1 and 5),
  aangemaakt timestamptz not null default now()
);
alter table toilet_bezoeken enable row level security;

-- Bestaande dagen omzetten naar losse keren (alleen als de tabel nog leeg is)
insert into toilet_bezoeken (kind_id, datum, hardheid)
select d.kind_id, d.datum, d.hardheid
from toilet_dagen d, generate_series(1, 30) g
where d.aantal > 0 and g <= d.aantal and not exists (select 1 from toilet_bezoeken);

-- 2. Per persoon apps verbergen (ouders beheren dit)
create table if not exists app_verbergen (
  user_id uuid not null references auth.users(id) on delete cascade,
  app text not null check (app in ('opruim', 'boodschappen', 'toilet', 'cadeautjes')),
  primary key (user_id, app)
);
alter table app_verbergen enable row level security;
create policy "verbergen lezen" on app_verbergen for select to authenticated using (user_id = auth.uid() or is_ouder());
create policy "verbergen beheren" on app_verbergen for all to authenticated using (is_ouder()) with check (is_ouder());

-- 3. Toilet-gegevens: ouder, of het kind zelf zolang de toilet-app voor dat kind niet is verborgen
drop policy if exists "toilet: ouder of het kind zelf" on toilet_dagen;
drop policy if exists "toilet toegang" on toilet_dagen;
create policy "toilet toegang" on toilet_dagen for all to authenticated
  using (is_ouder() or (kind_id in (select id from kinderen where user_id = auth.uid())
         and not exists (select 1 from app_verbergen v where v.user_id = auth.uid() and v.app = 'toilet')))
  with check (is_ouder() or (kind_id in (select id from kinderen where user_id = auth.uid())
         and not exists (select 1 from app_verbergen v where v.user_id = auth.uid() and v.app = 'toilet')));
drop policy if exists "toilet bezoeken toegang" on toilet_bezoeken;
create policy "toilet bezoeken toegang" on toilet_bezoeken for all to authenticated
  using (is_ouder() or (kind_id in (select id from kinderen where user_id = auth.uid())
         and not exists (select 1 from app_verbergen v where v.user_id = auth.uid() and v.app = 'toilet')))
  with check (is_ouder() or (kind_id in (select id from kinderen where user_id = auth.uid())
         and not exists (select 1 from app_verbergen v where v.user_id = auth.uid() and v.app = 'toilet')));
