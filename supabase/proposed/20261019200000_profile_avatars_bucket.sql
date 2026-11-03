-- Profile pictures: a public "avatars" bucket where each student can only
-- write inside their own folder ("<auth uid>/avatar.jpg").
--
-- The app resizes the picture on the phone (max 512x512 JPEG), uploads it, and
-- saves its public URL in profiles.profile_image (a column clients may
-- already update).
begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  2097152, -- 2 MB
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Public buckets serve files by URL without a policy. These cover uploading,
-- replacing (upsert needs select + update) and removing one's own picture.
drop policy if exists "Students read avatars" on storage.objects;
create policy "Students read avatars"
  on storage.objects for select to authenticated
  using (bucket_id = 'avatars');

drop policy if exists "Students upload their own avatar" on storage.objects;
create policy "Students upload their own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Students replace their own avatar" on storage.objects;
create policy "Students replace their own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Students delete their own avatar" on storage.objects;
create policy "Students delete their own avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

commit;
