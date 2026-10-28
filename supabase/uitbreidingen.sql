-- Uitbreidingen voor toilet-teller en boodschappen. Voer uit NA toilet.sql en boodschappen.sql.

-- Toilet: aantal keer per dag en zakjes (medicatie) genomen
alter table toilet_dagen add column if not exists aantal int not null default 0 check (aantal between 0 and 30);
alter table toilet_dagen add column if not exists zakjes boolean not null default false;
update toilet_dagen set aantal = 1 where geweest and aantal = 0;

-- Boodschappen: hoeveelheid + eenheid (st = stuk, g = gram). De eenheid wordt per product onthouden, de hoeveelheid niet.
alter table producten add column if not exists eenheid text not null default 'st' check (eenheid in ('st', 'g'));
alter table lijst add column if not exists hoeveelheid numeric check (hoeveelheid > 0);
alter table lijst add column if not exists eenheid text check (eenheid in ('st', 'g'));

-- Iedereen die ingelogd is mag alleen de eenheid van een product aanpassen (niet de naam of categorie)
revoke update on producten from authenticated;
grant update (eenheid) on producten to authenticated;
create policy "eenheid bijwerken" on producten for update to authenticated using (true) with check (true);
