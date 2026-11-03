-- Test-only data and assertions, run by audit_database.py in isolated PostgreSQL.
insert into auth.users values
('00000000-0000-0000-0000-000000000004','d@example.test',
 '{"username":"d","role":"ADMIN","status":"inactive","trial":999}');
do $$ begin
  assert (select role='USER' and status='active' and trial is null
    from profiles where username='d'), 'signup metadata escalation';
end $$;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  begin
    update profiles set role='ADMIN' where username='a';
    raise exception 'role update accepted';
  exception when insufficient_privilege then null; end;
  begin
    delete from profiles where username='a';
    raise exception 'profile delete accepted';
  exception when insufficient_privilege then null; end;
  assert (select count(*)=0 from mockboards_paused), 'cross-user read';
  begin
    insert into mockboards_paused(user_id, quiz_id) values
      ('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000009');
    raise exception 'cross-user insert accepted';
  exception when insufficient_privilege then null; end;
end $$;
update profiles set mantra='Safe edit ✓' where username='a';
do $$ declare c uuid; repeated uuid; begin
  c := (get_or_create_direct_chat('00000000-0000-0000-0000-000000000002')->>'id')::uuid;
  repeated := (get_or_create_direct_chat('00000000-0000-0000-0000-000000000002')->>'id')::uuid;
  assert c=repeated, 'duplicate direct chat';
  begin
    insert into chat_members values (c,'00000000-0000-0000-0000-000000000003','owner',now(),null);
    raise exception 'third party added';
  exception when insufficient_privilege then null; end;
  begin
    update chat_conversations set created_by='00000000-0000-0000-0000-000000000003' where id=c;
    raise exception 'conversation forged';
  exception when insufficient_privilege then null; end;
  insert into chat_messages(conversation_id,sender_id,body,created_at)
    values(c,auth.uid(),'Hello ✓', '2099-01-01');
  assert (select latest_message='Hello ✓' and last_message_at < now()+interval '1 minute'
    from chat_conversations where id=c), 'atomic preview / timestamp';
  begin
    insert into chat_messages(conversation_id,sender_id,body) values(c,auth.uid(),repeat('x',10001));
    raise exception 'oversized message accepted';
  exception when check_violation then null; end;
  assert (select bool_and(email is null) from search_profiles_for_chat('b@example.test',20)), 'email leak';
  assert (select count(*)=0 from chat_profile_summaries(array['00000000-0000-0000-0000-000000000003'::uuid])), 'unrelated profile leak';
  perform set_config('realtime.topic','chat-typing:'||c::text,false);
  insert into realtime.messages values ('broadcast');
end $$;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
do $$ begin
  assert (select count(*)=0 from chat_messages), 'outsider reads messages';
  assert (select count(*)=0 from realtime.messages), 'outsider reads typing';
  begin
    insert into realtime.messages values ('broadcast');
    raise exception 'outsider sends typing';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
-- Disjoint streak groups previously multiplied active_days through the join.
insert into quiz_attempts(student_id,attempted_at,score)
select '00000000-0000-0000-0000-000000000001',
  (date_trunc('month',timezone('Asia/Manila',now())) + n*interval '1 day') at time zone 'Asia/Manila',75
from unnest(array[0,1,4]) as n;
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  assert (select active_days=3 and longest_streak=2 from get_monthly_streak_achievians(10)), 'streak overcount';
end $$;
reset role;
set role anon;
set request.jwt.claim.sub = '';
do $$ begin
  assert (select count(*)=0 from profiles), 'anonymous profile access';
  assert (select count(*)=0 from chat_messages), 'anonymous chat access';
  assert (select count(*)=0 from mockboards_paused), 'anonymous paused access';
  begin
    perform get_or_create_direct_chat('00000000-0000-0000-0000-000000000002');
    raise exception 'anonymous RPC accepted';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
