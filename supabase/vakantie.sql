-- Vakantiedagen in de opruimstreak: tellen niet mee en breken de streak niet.
-- Plak dit in Supabase: SQL Editor > New query > Run
alter table dagen drop constraint if exists dagen_status_check;
alter table dagen add constraint dagen_status_check
  check (status in ('opgeruimd', 'rommel', 'joker', 'vakantie'));
