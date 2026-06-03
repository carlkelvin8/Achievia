# API Migration and Bug Fix Plan

## Goal

Finish the Flutter migration away from legacy REST/API plumbing and keep Supabase as the direct backend layer through datasources, lightweight repositories, and GoRouter-managed auth redirects.

## Completed in this pass

- Resolved the unmerged Git index for the five conflict files:
  - `lib/const.dart`
  - `lib/data/data_source/profile/profile_remote_datasource.dart`
  - `lib/data/models/quiz/qotd_dto.g.dart`
  - `lib/data/models/quiz/questions_dto.g.dart`
  - `lib/presentation/widgets/list_items/logo_meaning_section.dart`
- Kept the Supabase constants and removed the old `BASE_URL` conflict side.
- Kept the Supabase profile datasource instead of the old Dio profile implementation.
- Removed stale `token` and `id` parameters from the questions datasource, repository, use case, and provider flow.
- Removed stale auth-token threading from reviewer module pagination. The modules datasource now derives the current user from Supabase session context.
- Fixed `NetworkInfoImpl` for `connectivity_plus` 7, where `checkConnectivity()` returns a list of results.

## Remaining Cleanup Order

1. Remove or rename API-era domain naming where it is worth the churn.
   - Current paths such as `domain/entities/api/...` are naming debt, not active REST usage.
   - Do this as a separate broad rename only after the current feature branch is stable.

2. Replace production `print` calls with `debugPrint` or a logging helper.
   - Start with `data/repositoryImpl/questions/*`, `data/repositoryImpl/reviewer/module_repository_impl.dart`, and `presentation/provider/questions/questions_provider.dart`.

3. Clean up direct token storage usage.
   - `LocalStorageService` still exposes token persistence and `token_state_provider.dart` still streams Supabase access tokens.
   - Keep only flows that are needed by UI state; avoid passing tokens through repository/use case APIs.

4. Fix package/lint hygiene.
   - `core/network/offline_caching.dart` imports `package:path/path.dart`; add `path` as a direct dependency once the lockfile update is allowed.
   - Rename snake_case DTO/entity fields only when JSON mappings are handled safely with `@JsonKey`.

5. Modernize Flutter deprecations.
   - Replace `withOpacity` with `withValues(alpha: ...)`.
   - Migrate deprecated `RadioListTile.groupValue/onChanged` usage to the current RadioGroup pattern when UI behavior can be checked.

6. Verify after each step.
   - Run `dart format` on touched files.
   - Run `dart analyze`.
   - Scan for `Dio`, `http.`, `BASE_URL`, `Navigator.push`, `pushReplacement`, and stale token parameters.
