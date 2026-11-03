-- Daily Motivations: every message is at least 150 characters, so the
-- homepage banner shows a full, meaningful message.
--
-- Replaces the five starter messages of 20261003000000 (all shorter than 150
-- characters) with longer versions. Only rows whose text is still exactly the
-- original starter text are changed; messages written or edited by an admin
-- are left alone. The app's admin screen enforces the minimum for new and
-- edited messages (DailyMotivationEntity.minMessageLength).
--
-- No CHECK constraint is added: existing short admin messages would then make
-- every later update of their row (even turning it off) fail.
--
-- Check afterwards:
--   select char_length(message), message from public.daily_motivations
--   order by display_order;

begin;

update public.daily_motivations as m
set message = v.new_message
from (values
  ('You didn''t come this far to only come this far. Every late night, every sacrificed moment, they are all shaping your victory. Keep going.',
   'You didn''t come this far to only come this far. Every late night, every sacrificed weekend and every page you reviewed is shaping your victory. Keep going, future RMT; your license is closer than it looks.'),
  ('Small steps every day add up to the license you are working for.',
   'Small steps every day add up to the license you are working for. One topic, one practice set and one honest review at a time: consistency, not perfection, is what carries you to the board exam.'),
  ('Trust your preparation. Future RMT, you are more ready than you think.',
   'Trust your preparation, future RMT. You are more ready than you think. Every question you got wrong taught you something, and every question you got right proves you belong in this profession.'),
  ('Discipline today is the confidence you will carry into the board exam.',
   'Discipline today is the confidence you will carry into the board exam. When motivation fades, let your routine carry you: show up, study what is hard, and let today''s effort speak for you tomorrow.'),
  ('Rest if you must, but do not quit. Your future patients are counting on you.',
   'Rest if you must, but do not quit. Your future patients are counting on the knowledge you are building now. Take a breath, drink some water, and come back to your review with a clear, steady mind.')
) as v(old_message, new_message)
where lower(btrim(m.message)) = lower(btrim(v.old_message))
  -- the unique index on lower(btrim(message)) must not be violated
  and not exists (
    select 1 from public.daily_motivations d
    where lower(btrim(d.message)) = lower(btrim(v.new_message))
  );

notify pgrst, 'reload schema';
commit;
