-- De Dramameter bewaart niets. Dit bestand zorgt er alleen voor dat de app via
-- "Wie ziet welke apps?" aan of uit gezet kan worden. Voer uit NA uitbreidingen2.sql.

alter table app_verbergen drop constraint if exists app_verbergen_app_check;
alter table app_verbergen add constraint app_verbergen_app_check
  check (app in ('opruim', 'boodschappen', 'toilet', 'cadeautjes', 'drama'));

-- Heb je een eerdere versie van dit bestand uitgevoerd? Dan mag je de overbodige tabel verwijderen:
-- drop table if exists drama_momenten;
