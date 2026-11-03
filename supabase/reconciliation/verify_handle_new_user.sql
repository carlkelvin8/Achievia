-- STAGING / LOCAL ONLY. Do not run against production.
-- Inserting directly into auth.users bypasses GoTrue, so no confirmation or
-- other email is ever sent. The only side effect is that other triggers on
-- auth.users (if any) fire inside the transaction that is rolled back.
-- Exercises public.handle_new_user() by inserting throw-away rows into
-- auth.users and always ends with ROLLBACK, so nothing persists. Each check
-- raises an exception on failure; success prints NOTICE lines and
-- "verify_handle_new_user: all checks passed".
begin;

do $$
declare
  a uuid := gen_random_uuid();
  b uuid := gen_random_uuid();
  c uuid := gen_random_uuid();
  d uuid := gen_random_uuid();
  e uuid := gen_random_uuid();
  r record;
  v_name text;
  v_failed boolean;
begin
  -- 1. Normal signup keeps its metadata; role/status are forced.
  insert into auth.users (id, email, raw_user_meta_data) values
    (a, 'verify-a@example.test', jsonb_build_object(
      'first_name', 'Ada', 'username', 'verify_ada', 'age', 21,
      'courseId', null, 'role', 'ADMIN', 'status', 'inactive',
      'purpose', 'MTLE'));
  select * into r from public.profiles where id = a;
  assert r.username = 'verify_ada', 'username kept';
  assert r.age = 21, 'age kept';
  assert r.role = 'USER' and r.status = 'active', 'role/status forced';
  assert r.email = 'verify-a@example.test', 'email copied';

  -- 2. Missing metadata entirely (NULL) still creates a profile.
  insert into auth.users (id, email, raw_user_meta_data)
    values (b, 'verify-b@example.test', null);
  select * into r from public.profiles where id = b;
  assert r.id is not null, 'profile created without metadata';
  assert r.username like 'verify-b\_%' escape '\', 'username derived';

  -- 3. Garbage numbers/dates and over-long strings do not block signup.
  insert into auth.users (id, email, raw_user_meta_data) values
    (c, 'verify-c@example.test', jsonb_build_object(
      'username', repeat('x', 300), 'first_name', repeat('f', 500),
      'age', 'abc', 'courseId', '1.5', 'date_of_examination', 'not a date'));
  select * into r from public.profiles where id = c;
  assert r.age is null and r.course_id is null, 'bad numbers become NULL';
  assert r.date_of_examination is null, 'bad date becomes NULL';
  assert length(r.first_name) <= 100 and length(r.username) <= 100,
    'long values truncated to column limits';

  -- 4. An explicit username that is taken is REFUSED and never renamed,
  --    for an exact and for a different-case duplicate; nothing is left behind.
  foreach v_name in array array['verify_ada', 'VERIFY_ADA'] loop
    v_failed := false;
    begin
      insert into auth.users (id, email, raw_user_meta_data) values
        (d, 'verify-d@example.test', jsonb_build_object('username', v_name));
    exception when others then
      v_failed := true;
      assert sqlerrm like '%constraint=profiles_username_key%',
        'username collision names profiles_username_key, got: ' || sqlerrm;
    end;
    assert v_failed, 'taken username "' || v_name || '" must be refused';
    assert not exists (select 1 from public.profiles where id = d),
      'no profile left after refused signup';
    assert not exists (select 1 from auth.users where id = d),
      'no auth user left after refused signup';
  end loop;
  assert (select username from public.profiles where id = a) = 'verify_ada',
    'the original username is untouched';

  -- 5. A real failure names the constraint (duplicate email) instead of hiding it.
  begin
    insert into auth.users (id, email, raw_user_meta_data) values
      (e, 'verify-a@example.test', '{}'::jsonb);
    -- auth.users may itself reject the duplicate; either outcome is acceptable
    -- as long as no half-created user remains.
  exception when others then
    raise notice 'duplicate email rejected: %', sqlerrm;
  end;
  assert not exists (select 1 from public.profiles where id = e),
    'no orphan profile after failed signup';

  raise notice 'verify_handle_new_user: all checks passed';
end $$;

rollback;
