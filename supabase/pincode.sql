-- Inloggen met pincode voor iedereen (ouders én kinderen). Voer uit NA kindlogin.sql.
-- Ouders krijgen net als kinderen een verzonnen inlogadres + naam, zodat ze in de lijst "Wie ben jij?" staan.

alter table ouders add column if not exists naam text;
alter table ouders add column if not exists emoji text default '🧑';
alter table ouders add column if not exists login_email text;

-- Naam, emoji en verzonnen adres moeten leesbaar zijn vóór het inloggen
create policy "profielen lezen" on ouders for select to anon, authenticated using (true);

-- Per ouder (na het aanmaken van het account in Authentication > Users > Add user,
-- met een verzonnen adres, een pincode als wachtwoord en Auto Confirm User aan):
-- insert into ouders (user_id, naam, emoji, login_email)
--   select id, 'Papa', '🧔', email from auth.users where email = 'papa@gezin.example.com'
--   on conflict (user_id) do update set naam = excluded.naam, emoji = excluded.emoji, login_email = excluded.login_email;
