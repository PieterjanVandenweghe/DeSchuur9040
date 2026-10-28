-- Voer uit NA schema.sql en kindlogin.sql (gebruikt is_ouder()).
-- Gevoelige gegevens: NIET leesbaar zonder inloggen; alleen de ouder en het kind zelf.

create table toilet_dagen (
  kind_id uuid not null references kinderen(id) on delete cascade,
  datum date not null,
  geweest boolean not null default false,
  hardheid int check (hardheid between 1 and 5),
  buikpijn boolean not null default false,
  primary key (kind_id, datum)
);
alter table toilet_dagen enable row level security;
create policy "toilet: ouder of het kind zelf" on toilet_dagen for all to authenticated
  using (is_ouder() or kind_id in (select id from kinderen where user_id = auth.uid()))
  with check (is_ouder() or kind_id in (select id from kinderen where user_id = auth.uid()));
