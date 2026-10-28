# DeSchuur9040-app

Een site met drie modules: **Opruimstreak** (streak + jokers + schermtijd), **Boodschappen** (lijst per winkelroute) en **Toilet-teller**. Gehost op GitHub Pages, gegevens in Supabase (gratis). Iedereen logt in met naam en pincode.

## Structuur
- `docs/index.html`: startscherm. `docs/opruim/`, `docs/boodschappen/`, `docs/toilet/`: de modules. `docs/gedeeld/`: gedeelde stijl en inlogcode.
- `docs/config.js`: Supabase-gegevens en instellingen, voor alle modules.
- `supabase/*.sql`: de database.
- `.github/workflows/keepalive.yml`: voorkomt dat het gratis Supabase-project na 7 dagen inactiviteit pauzeert.

## Installatie

### 1. Supabase
1. Maak op supabase.com een gratis project.
2. Voer in de **SQL Editor** in deze volgorde uit, elk bestand Ã©Ã©n keer:
   `schema.sql` > `kindlogin.sql` > `pincode.sql` > `privacy.sql` > `boodschappen.sql` > `toilet.sql`
   (`schema.sql` bevat voorbeeldnamen; pas de echte namen en emoji's later aan in **Table Editor > kinderen**.)
3. **Authentication > Sign In / Providers > Email**: zet "Allow new users to sign up" **uit**.
4. Maak voor iedere ouder en ieder kind een account via **Authentication > Users > Add user > Create new user**:
   - e-mail: `<inlognaam>@gezin.example.com` (kleine letters, geen spaties of accenten; het domein moet gelijk zijn aan `LOGIN_DOMEIN` in `docs/config.js`)
   - wachtwoord: de pincode (ouders liefst 8 cijfers, kinderen minstens 6)
   - **Auto Confirm User** aan
5. Koppel de accounts (SQL Editor, met jouw gegevens):
   ```sql
   -- ouder
   insert into ouders (user_id, naam, emoji)
     select id, 'Papa', 'ðŸ§”' from auth.users where email = 'papa@gezin.example.com' on conflict do nothing;
   -- kind (login_email = het adres van het account)
   update kinderen set login_email = 'emma@gezin.example.com' where volgorde = 1;
   update kinderen k set user_id = u.id from auth.users u where u.email = k.login_email;
   ```
6. Kopieer onder **Project Settings > API** de *Project URL* en de *anon public key*.

### 2. GitHub
1. Zet de inhoud van deze map in de root van een repo (inclusief `.github/`).
2. Vul `SUPABASE_URL` en `SUPABASE_ANON_KEY` in `docs/config.js` in.
3. **Settings > Pages**: Source = *Deploy from a branch*, branch `main`, map `/docs`.
4. **Settings > Secrets and variables > Actions**: voeg `SUPABASE_URL` en `SUPABASE_ANON_KEY` toe en test de keepalive via **Actions > Supabase keepalive > Run workflow**.

De site staat dan op `https://<gebruiker>.github.io/<repo>/`. Zet hem op het startscherm van de tablets via "Zet op beginscherm".

## Spelregels (aanpasbaar)
- **Opruimen**: elke avond beoordeelt een ouder per kind (Opgeruimd/Rommel). 7 opgeruimde dagen = 1 joker (max. 2). Bij rommel is de streak weg en volgende dag minder tijd, tenzij een joker wordt ingezet. Per kind instelbaar in de tabel `kinderen`: `beperking` (bv. Social media of Schermtijd), `basis_minuten`, `straf_minuten`. Overige instellingen in `docs/config.js`. Een kind kan na een rommeldag zelf een joker aanvragen; de ouder keurt goed of af. Dagen zonder beoordeling tellen niet mee. Een ouder kan bovenaan een andere dag kiezen.
- **Boodschappen**: tab *Lijst* (typen, aanvullen uit de catalogus, nieuw product meteen bewaard), tab *Winkelen* (afvinken in de volgorde van de gekozen winkel), tab *Beheer* voor ouders (winkels, volgorde van categorieÃ«n per winkel, producten, categorieÃ«n). Wijzigingen verschijnen live op andere toestellen.
- **Toilet-teller**: per dag geweest ja/nee, hoe het was (5-delige schaal, aanpasbaar bovenaan `docs/toilet/index.html`) en buikpijn ja/nee. Alleen de ouder en het kind zelf zien en vullen dit in.

## Beveiliging: wat is openbaar en wat niet
- **De site-link is publiek.** GitHub Pages kan een pagina niet afschermen (op de gratis variant moet de repo zelfs publiek zijn). Zonder naam en pincode toont elke pagina alleen het inlogscherm en geeft de database niets vrij. Alle pagina's hebben `noindex`.
- **`docs/config.js` is openbaar**, en dat is de bedoeling: de *Project URL* en de *anon public key* zijn badges voor niet-ingelogde bezoekers. Wat iemand ermee kan, bepalen de rechtenregels (RLS) in de database.
- **Nooit de `service_role` key** in de repo, in `config.js` of in de GitHub-secrets zetten. Die omzeilt alle rechten en de app heeft hem niet nodig.
- **Elke nieuwe tabel moet RLS aan hebben** (`alter table ... enable row level security;` plus regels). Een tabel zonder RLS is leesbaar met de anon key. Controleer dit in Supabase onder **Advisors > Security Advisor**.
- **Echte namen en e-mailadressen horen niet in de repo.** Houd de SQL-bestanden generiek en pas namen aan in Supabase zelf.
- **Pincodes zijn zwakker dan wachtwoorden.** Supabase beperkt het aantal pogingen, maar neem voor ouders liefst 8 cijfers. Ook `LOGIN_DOMEIN` (het patroon van de inlogadressen) is zichtbaar.
- **Aanmelden is uitgezet**, zodat niemand zelf een account kan maken. Nieuwe gebruikers maak je alleen in het dashboard aan.

## Beheer
- **Nieuwe ouder**: account maken (stap 4) en de `insert into ouders`-regel uit stap 5 uitvoeren. Een ouder verwijderen: rij uit `ouders` wissen en eventueel de gebruiker.
- **Namen of emoji's wijzigen**: Table Editor > `kinderen`, of `update kinderen set naam = 'Emma', emoji = 'ðŸ‘' where volgorde = 1;`.
- **Pincode vergeten**: Authentication > Users > de gebruiker kiezen en een nieuw wachtwoord instellen, of een nieuw account aanmaken.
- **Inlognaam wijzigen**: het e-mailadres van de gebruiker aanpassen; zie de voorbeeld-SQL onderaan `supabase/privacy.sql`.
