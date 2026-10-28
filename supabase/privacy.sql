-- Eerst inloggen, dan pas de rest: niets meer leesbaar zonder pincode. Voer uit NA pincode.sql.

drop policy if exists "lezen kinderen" on kinderen;
drop policy if exists "lezen dagen" on dagen;
drop policy if exists "profielen lezen" on ouders;

create policy "lezen kinderen" on kinderen for select to authenticated using (true);
create policy "lezen dagen" on dagen for select to authenticated using (true);
-- ouders: alleen de eigen rij is leesbaar (policy "ouder ziet eigen rij" uit kindlogin.sql blijft staan)

-- De inlognaam (het stuk voor de @) moet passen bij het adres in Authentication > Users.
-- Voorbeeld om bestaande accounts te hernoemen naar <naam>@gezin.example.com (zelfde gebruiker, zelfde pincode):
-- update auth.users set email = 'emma@gezin.example.com' where email = 'emma@kinderen.example.com';
-- update auth.identities set identity_data = jsonb_set(identity_data, '{email}', '"emma@gezin.example.com"')
--   where provider = 'email' and user_id = (select id from auth.users where email = 'emma@gezin.example.com');
