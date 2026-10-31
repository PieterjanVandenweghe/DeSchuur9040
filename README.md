# Thuis-app 🏠

Eén site met drie modules: **Opruimstreak** (streak + jokers + schermtijd), **Boodschappen** (lijst per winkelroute) en **Toilet-teller**. Gehost op GitHub Pages, gegevens in Supabase (gratis). Iedereen logt in met naam en pincode.

## Structuur
- `docs/index.html`: startscherm. `docs/opruim/`, `docs/boodschappen/`, `docs/toilet/`: de modules. `docs/gedeeld/`: gedeelde stijl en inlogcode.
- `docs/config.js`: instellingen voor alle modules. De Supabase-gegevens staan er als plaatsaanduiding en worden bij het uitrollen ingevuld.
- `supabase/*.sql`: de database.
- `.github/workflows/deploy.yml`: vult de configuratie in en zet de site online. `lokaal.py`: lokaal testen met je eigen gegevens.
- `.github/workflows/keepalive.yml`: voorkomt dat het gratis Supabase-project na 7 dagen inactiviteit pauzeert.

## Installatie

### 1. Supabase
1. Maak op supabase.com een gratis project.
2. Voer in de **SQL Editor** in deze volgorde uit, elk bestand één keer:
   `schema.sql` > `kindlogin.sql` > `pincode.sql` > `privacy.sql` > `boodschappen.sql` > `toilet.sql` > `uitbreidingen.sql` > `cadeautjes.sql` (en `cadeautjes-prijs.sql` als je cadeautjes.sql al eerder uitvoerde) > `cadeautjes-ouders.sql` > `uitbreidingen2.sql` > `drama.sql`
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
     select id, 'Papa', '🧔' from auth.users where email = 'papa@gezin.example.com' on conflict do nothing;
   -- kind (login_email = het adres van het account)
   update kinderen set login_email = 'emma@gezin.example.com' where volgorde = 1;
   update kinderen k set user_id = u.id from auth.users u where u.email = k.login_email;
   ```
6. Kopieer onder **Project Settings > API** de *Project URL* en de *anon public key*.

### 2. GitHub
1. Zet de inhoud van deze map in de root van een repo (inclusief `.github/`).
2. Laat `docs/config.js` zoals het is: de Supabase-waarden staan er als plaatsaanduiding (`__SUPABASE_URL__`, `__SUPABASE_ANON_KEY__`) en worden bij het uitrollen ingevuld. Zet er nooit echte sleutels in.
3. **Settings > Secrets and variables > Actions**: voeg `SUPABASE_URL` en `SUPABASE_ANON_KEY` toe (zelfde waarden als in Supabase). Doe dit vóór de eerste uitrol.
4. **Settings > Pages**: Source = *GitHub Actions*. Push naar `main` of start **Actions > Site uitrollen > Run workflow**. De workflow `keepalive.yml` gebruikt dezelfde secrets; test hem via **Actions > Supabase keepalive > Run workflow**.

De site staat dan op `https://<gebruiker>.github.io/<repo>/`. Zet hem op het startscherm van de tablets via "Zet op beginscherm".

## Spelregels (aanpasbaar)
- **Opruimen**: elke avond beoordeelt een ouder per kind (Opgeruimd/Rommel). 7 opgeruimde dagen = 1 joker (max. 2). Bij rommel is de streak weg en volgende dag minder tijd, tenzij een joker wordt ingezet. Per kind instelbaar in de tabel `kinderen`: `beperking` (bv. Social media of Schermtijd), `basis_minuten`, `straf_minuten`. Overige instellingen in `docs/config.js`. Een kind kan na een rommeldag zelf een joker aanvragen; de ouder keurt goed of af. Dagen zonder beoordeling tellen niet mee. Een ouder kan bovenaan een andere dag kiezen.
- **Boodschappen**: tab *Lijst* (typen, aanvullen uit de catalogus, nieuw product meteen bewaard), tab *Winkelen* (afvinken in de volgorde van de gekozen winkel), tab *Beheer* voor ouders (winkels, volgorde van categorieën per winkel, producten, categorieën). Wijzigingen verschijnen live op andere toestellen.
- **Boodschappen, hoeveelheden**: bij het toevoegen kun je een aantal en een eenheid (st of g) kiezen. De eenheid wordt per product onthouden, het aantal niet.
- **Toilet-teller**: elke keer naar het toilet wordt apart toegevoegd met een eigen score (5-delige schaal, aanpasbaar bovenaan `docs/toilet/index.html`, of "weet niet"), per dag buikpijn ja/nee en zakjes genomen ja/nee. Ouders zien daarnaast een overzicht per datum (14, 30 of 90 dagen) met per keer de score en een samenvatting. Alleen de ouder en het kind zelf zien en vullen dit in.
- **Dramameter** (puur voor de grap, er wordt niets bewaard): kies wie er drama maakt (een gezinslid, jezelf of "iemand anders" met een vrije naam, voor iedereen die is ingelogd, ook kinderen) en schuif de slider van 1 tot 10. Dan volgt een scherm bij dat niveau (beven, sirene, grappige uitspraak) en een korte reset met een ademcirkel en een herstelopdracht. Geen geschiedenis, geen tellers, geen gevolgen. Tekst en opdrachten staan bovenaan in `docs/drama/index.html`.
- **Cadeautjes**: een lijstje per gezinslid. Iedereen die is ingelogd kan iets toevoegen (standaard voor zichzelf, aanpasbaar) met een optionele link en een optionele prijsrange (bv. €10–20, of "tot €15"), zodat iedereen een idee heeft van de kostprijs. Anderen kunnen "Ik koop dit" aanduiden; de eigenaar van het lijstje ziet dat niet, zodat het een verrassing blijft. Ouders kunnen per lijstje een geheime deellink maken voor mensen zonder account (opa, oma). Wie die link heeft, kan het lijstje zien en aanduiden wat hij of zij koopt. Geef de link niet aan de eigenaar van het lijstje zelf. Alleen ouders kunnen per cadeautje aanduiden of het via de deellink gedeeld wordt (standaard niet) en een eigen label "gevraagd aan" toevoegen; kinderen zien dat niet.

## Beveiliging: wat is openbaar en wat niet
- **De site-link is publiek.** GitHub Pages kan een pagina niet afschermen (op de gratis variant moet de repo zelfs publiek zijn). Zonder naam en pincode toont elke pagina alleen het inlogscherm en geeft de database niets vrij. Alle pagina's hebben `noindex`.
- **De Supabase-URL en de anon key staan niet in de repo**: ze komen uit GitHub-secrets en worden bij het uitrollen in `config.js` ingevuld. De uitgerolde site bevat ze wel, want de browser heeft ze nodig; ze zijn bedoeld als openbare badge voor niet-ingelogde bezoekers. Wat iemand ermee kan, bepalen de rechtenregels (RLS). Staan er eerder echte waarden in je Git-geschiedenis, dan blijven die daar; voor een anon key is dat geen probleem.
- **Nooit de `service_role` key** in de repo, in `config.js` of in de GitHub-secrets zetten. Die omzeilt alle rechten en de app heeft hem niet nodig.
- **Elke nieuwe tabel moet RLS aan hebben** (`alter table ... enable row level security;` plus regels). Een tabel zonder RLS is leesbaar met de anon key. Controleer dit in Supabase onder **Advisors > Security Advisor**.
- **Echte namen en e-mailadressen horen niet in de repo.** Houd de SQL-bestanden generiek en pas namen aan in Supabase zelf.
- **Pincodes zijn zwakker dan wachtwoorden.** Supabase beperkt het aantal pogingen, maar neem voor ouders liefst 8 cijfers. Ook `LOGIN_DOMEIN` (het patroon van de inlogadressen) is zichtbaar.
- **Deellinks voor cadeautjes** zijn de enige openbare toegang: wie de lange geheime link heeft, ziet één lijstje en kan alleen iets aanduiden. Trek een link in via de pagina Cadeautjes (ouders) als hij verkeerd terechtkomt.
- **Aanmelden is uitgezet**, zodat niemand zelf een account kan maken. Nieuwe gebruikers maak je alleen in het dashboard aan.

## Beheer
- **Nieuwe ouder**: account maken (stap 4) en de `insert into ouders`-regel uit stap 5 uitvoeren. Een ouder verwijderen: rij uit `ouders` wissen en eventueel de gebruiker.
- **Namen of emoji's wijzigen**: Table Editor > `kinderen`, of `update kinderen set naam = 'Emma', emoji = '🏑' where volgorde = 1;`.
- **Pincode vergeten**: Authentication > Users > de gebruiker kiezen en een nieuw wachtwoord instellen, of een nieuw account aanmaken.
- **Inlognaam wijzigen**: het e-mailadres van de gebruiker aanpassen; zie de voorbeeld-SQL onderaan `supabase/privacy.sql`.

## Wie ziet welke apps?
Ouders kunnen op het startscherm onder **⚙️ Wie ziet welke apps?** per persoon aan- of uitvinken welke apps zichtbaar zijn (voer eerst `supabase/uitbreidingen2.sql` uit). Een verborgen app verdwijnt als tegel en meldt "niet beschikbaar" als iemand de link toch opent. Voor de toilet-teller is dat ook in de database afgedwongen: een kind waarvoor die app is uitgezet, kan de gegevens niet meer lezen of schrijven. Bij de andere apps gaat het om zichtbaarheid, niet om een extra slot op de gegevens.

## Lokaal testen
Maak een bestand `.env.local` (zie `.env.local.voorbeeld`; staat in `.gitignore`) met `SUPABASE_URL` en `SUPABASE_ANON_KEY`, en start `python lokaal.py`. Het script maakt een kopie in `_site/` met de ingevulde waarden en toont de site op http://localhost:8000. Herstart het na elke wijziging in `docs/`.
