-- Eenheid ml (milliliter) erbij naast st (stuk) en g (gram). Voer uit NA uitbreidingen.sql en recepten-ingredienten.sql.
-- Het script zoekt de oude controleregels op de eenheid-kolommen op, vervangt ze en laat alle gegevens staan.

do $$
declare r record;
begin
  for r in
    select c.conrelid::regclass::text as t, c.conname
    from pg_constraint c
    where c.contype = 'c'
      and c.conrelid::regclass::text in ('producten', 'lijst', 'recept_ingredienten')
      and pg_get_constraintdef(c.oid) like '%eenheid%'
  loop
    execute format('alter table %s drop constraint %I', r.t, r.conname);
  end loop;

  alter table producten add constraint producten_eenheid_check check (eenheid in ('st', 'g', 'ml'));
  alter table lijst add constraint lijst_eenheid_check check (eenheid is null or eenheid in ('st', 'g', 'ml'));
  if to_regclass('public.recept_ingredienten') is not null then
    alter table recept_ingredienten add constraint recept_ingredienten_eenheid_check check (eenheid in ('st', 'g', 'ml'));
  end if;
end $$;
