-- Toilet: buikpijn/zakjes mogen leeg zijn (= nog niet beantwoord), zodat één vraag de andere niet invult.
-- Plak dit in Supabase: SQL Editor > New query > Run
alter table toilet_dagen alter column buikpijn drop not null, alter column buikpijn drop default;
alter table toilet_dagen alter column zakjes drop not null, alter column zakjes drop default;
