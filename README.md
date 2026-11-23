# De Schuur 🏠

Een kleine gezinssite met een paar modules, gehost op GitHub Pages met de gegevens in Supabase (gratis). Iedereen logt in met naam en pincode.

## Modules
- **Opruimstreak**: dagelijkse opvolging per kind met een streak en jokers.
- **Boodschappen**: gedeeld boodschappenlijstje, geordend per winkel.
- **Toilet-teller**: dagelijkse opvolging per kind; alleen zichtbaar voor ouders en het kind zelf.
- **Cadeautjes**: verlanglijstjes, met geheime deellinks voor familie zonder account.
- **Menu & recepten**: weekmenu en receptenlijst, gekoppeld aan het boodschappenlijstje.
- **Barometer**: een meter voor de grap; er wordt niets bewaard.

Instellingen staan bovenaan elk script in `docs/<module>/index.html` en in `docs/config.js`.

## Structuur
- `docs/`: de site. `docs/index.html` is het startscherm, `docs/gedeeld/` bevat de gedeelde stijl en code.
- `docs/config.js`: de Supabase-gegevens staan er als plaatsaanduiding en worden bij het uitrollen ingevuld.
- `supabase/*.sql`: de database. `supabase/functions/recept-import/`: Edge Function voor het importeren van recepten en productfoto's.
- `.github/workflows/deploy.yml`: zet de site online. `keepalive.yml`: voorkomt dat het gratis Supabase-project pauzeert.
- `lokaal.py`: lokaal testen (zie onderaan).

## Installatie

### 1. Supabase
1. Maak op supabase.com een gratis project.
2. Voer in de **SQL Editor** in deze volgorde uit, elk bestand één keer:
   `schema.sql` > `kindlogin.sql` > `pincode.sql` > `privacy.sql` > `boodschappen.sql` > `toilet.sql` > `uitbreidingen.sql` > `cadeautjes.sql` > `cadeautjes-ouders.sql` > `uitbreidingen2.sql` > `drama.sql` > `menu.sql` > `recepten-ingredienten.sql` > `eenheid-ml.sql` > `toilet-onbeantwoord.sql` > `vakantie.sql` > `app-volgorde.sql` > `menu-personen-soep.sql` > `recepten-wijzigen.sql` > `cadeautjes-gevers.sql` > `cadeautjes-foto.sql` > **`gezin-beveiliging.sql` (altijd als laatste, en opnieuw na elk nieuw script)**.
   Optioneel: `testkind.sql`, `hoofdletters.sql`, `producten-hoofdletter.sql`.
   `schema.sql` bevat voorbeeldnamen; pas de echte namen aan in Supabase zelf, niet in de repo.
3. **Authentication > Sign In / Providers > Email**: zet "Allow new users to sign up" **uit**.
4. Maak voor ieder gezinslid een account via **Authentication > Users > Add user**: e-mail `<inlognaam>@<LOGIN_DOMEIN uit config.js>`, de pincode als wachtwoord, **Auto Confirm User** aan.
5. Koppel de accounts in de SQL Editor:
   ```sql
   insert into ouders (user_id, naam, emoji)
     select id, 'Papa', '🧔' from auth.users where email = 'papa@gezin.example.com' on conflict do nothing;
   update kinderen set login_email = 'emma@gezin.example.com' where volgorde = 1;
   update kinderen k set user_id = u.id from auth.users u where u.email = k.login_email;
   ```
6. **Edge Functions**: maak de functie `recept-import` met de code uit `supabase/functions/recept-import/index.ts`.

### 2. GitHub
1. **Settings > Secrets and variables > Actions**: voeg `SUPABASE_URL` en `SUPABASE_ANON_KEY` toe (Project Settings > API in Supabase).
2. **Settings > Pages**: Source = *GitHub Actions*. Push naar `main` of start **Actions > Site uitrollen > Run workflow**.

## Beveiliging
- **De site is publiek, de gegevens niet.** Zonder login toont elke pagina enkel het inlogscherm. Alle pagina's hebben `noindex`.
- **Sleutels:** de Supabase-URL en de anon key komen uit GitHub-secrets. De uitgerolde site bevat ze, want de browser heeft ze nodig; wat iemand ermee kan, bepalen de rechtenregels (RLS). Zet **nooit** de `service_role` key in de repo, in `config.js` of in de secrets.
- **Twee sloten:** aanmelden staat uit, en `gezin-beveiliging.sql` laat alleen gekoppelde gezinsleden toe. Een los account ziet en wijzigt niets. Het controleblok onderaan dat script hoort leeg te zijn.
- **Nieuwe tabel?** Zet RLS aan, voer `gezin-beveiliging.sql` opnieuw uit en kijk in **Advisors > Security Advisor**.
- **Edge Function:** werkt alleen voor ingelogde gezinsleden en haalt alleen publieke adressen op. Zet ze na een wijziging opnieuw online via het dashboard.
- **Deellinks** (cadeautjes) zijn de enige toegang zonder account. Trek een link in als hij verkeerd terechtkomt.
- **Kies lange pincodes**, en houd echte namen, e-mailadressen en persoonlijke details uit de repo.

## Beheer
- **Pincode vergeten**: Authentication > Users > gebruiker kiezen > nieuw wachtwoord.
- **Namen of emoji's**: Table Editor > `kinderen` of `ouders`.
- **Wie ziet welke apps**: als ouder op het startscherm onder ⚙️.

## Lokaal testen
Maak `.env.local` (staat in `.gitignore`) met `SUPABASE_URL` en `SUPABASE_ANON_KEY`, en start `python lokaal.py`. De site draait dan op http://localhost:8000. Herstart na elke wijziging in `docs/`.
