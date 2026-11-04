-- Testkind: een gewoon kind in de database, maar alleen zichtbaar voor één ouder (jij)
-- en voor het testkind zelf. Andere ouders en kinderen zien het nergens.
-- Voer uit NA privacy.sql (SQL Editor > New query > Run).

alter table kinderen add column if not exists test_voor uuid references auth.users(id) on delete cascade;
-- test_voor leeg = gewoon kind; ingevuld = testkind, alleen zichtbaar voor die gebruiker

drop policy if exists "lezen kinderen" on kinderen;
create policy "lezen kinderen" on kinderen for select to authenticated
  using (test_voor is null or test_voor = auth.uid() or user_id = auth.uid());

-- Dagen van een testkind ook verbergen (een subquery op kinderen volgt de policy hierboven)
drop policy if exists "lezen dagen" on dagen;
create policy "lezen dagen" on dagen for select to authenticated
  using (kind_id in (select id from kinderen));

-- 1) Maak in Authentication > Users > Add user een account, bv. testkind@deschuur9040.com,
--    met een pincode als wachtwoord en Auto Confirm User aan.
-- 2) Vul hieronder JOUW inlogadres in en voer uit:
insert into kinderen (naam, emoji, volgorde, beperking, basis_minuten, straf_minuten, login_email, user_id, test_voor)
select 'Testkind', '🧪', 99, 'Schermtijd', 60, 15, u.email, u.id,
       (select id from auth.users where email = 'JOUW_NAAM@deschuur9040.com')
from auth.users u where u.email = 'testkind@deschuur9040.com';
