# Registration and Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make email signup correctly handle Supabase confirmation responses and use one consistent toast-style feedback API throughout the Flutter app.

**Architecture:** Keep feedback at the presentation boundary through an upgraded `AppToast` wrapper around Flutter's `ScaffoldMessenger`, with no new package. Represent signup's two successful states with a typed `SignupResult`, propagate Supabase errors through the existing datasource/repository/use-case layers, and let forms decide when to show feedback and navigate.

**Tech Stack:** Flutter/Dart 3.8.1, `supabase_flutter` 2.12.4, Riverpod 3, GoRouter 17, Material `SnackBar`, Flutter widget/unit tests.

**Spec:** `docs/superpowers/specs/2026-08-29-registration-feedback-design.md`

## Global Constraints

- Do not add a toast/snackbar package; use Flutter Material and the existing `snack_bar_utils.dart` location.
- Do not include passwords or tokens in Supabase user metadata.
- Keep inline validation, dialogs, loading indicators, and persistent full-page error states in their existing form.
- Use `achievia://callback` for mobile auth redirects; remote Dashboard allow-list changes are outside this repository task.
- Do not create a remote test user or modify live Supabase data.
- Do not run `git commit` or `git push`; the repository instructions explicitly prohibit both.
- Tests created only for this task are temporary and must be deleted after verification; preserve all pre-existing tests.

---

### Task 1: Establish the shared AppToast API with a failing widget test

**Files:**
- Modify: `lib/core/utils/snack_bar_utils.dart`
- Test: `test/core/utils/app_toast_test.dart` (temporary; delete after verification)

**Interfaces:**
- Produces `AppToast.showSuccess(BuildContext, String)`, `showError`, `showInfo`, and `showWarning`.
- Every public method renders one floating Material `SnackBar` through `ScaffoldMessenger.maybeOf` and uses the corresponding semantic icon/color.

- [ ] **Step 1: Write the failing widget test**

Create a `MaterialApp` with a `Scaffold` and a button that calls each `AppToast` method. For each variant, tap the button and assert the message and leading icon are rendered in the snackbar. The test must import `AppToast` even though it does not exist yet.

```dart
testWidgets('AppToast renders a success message', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppToast.showSuccess(context, 'Saved'),
            child: const Text('Show'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show'));
  await tester.pump();

  expect(find.text('Saved'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

Add equivalent cases for error (`Icons.error`), info (`Icons.info`), and warning (`Icons.warning`).

- [ ] **Step 2: Run the test and verify the expected failure**

Run: `flutter test --no-pub test/core/utils/app_toast_test.dart`

Expected: FAIL because `AppToast` and its methods are not yet defined.

- [ ] **Step 3: Implement the minimal shared helper**

Replace `SnackBarUtils` with `AppToast` in `lib/core/utils/snack_bar_utils.dart`. Use `AppColors.success`, `danger`, `info`, and `warning`; dismiss the current snackbar before showing the new one; render an icon plus an `Expanded` message; set `SnackBarBehavior.floating`; and use a four-second duration so error messages remain readable.

```dart
class AppToast {
  const AppToast._();

  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle);

  static void showError(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, AppColors.info, Icons.info);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, AppColors.warning, Icons.warning);

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}
```

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `flutter test --no-pub test/core/utils/app_toast_test.dart`

Expected: PASS for all four variants.

---

### Task 2: Add a typed signup result and preserve Supabase errors

**Files:**
- Create: `lib/domain/entities/api/auth/signup_result.dart`
- Create: `lib/data/models/auth/signup_result_dto.dart`
- Modify: `lib/data/data_source/auth/user_remote_datasource.dart:9-16,76-91`
- Modify: `lib/data/repositoryImpl/auth/user_repository_impl.dart:28-33`
- Modify: `lib/domain/repository/auth/user_repository.dart`
- Modify: `lib/domain/use_cases/auth/user_use_case.dart:14-17`
- Modify: `lib/data/models/auth/user_dto.dart:49-68`
- Test: `test/domain/entities/api/auth/signup_result_test.dart` (temporary; delete after verification)

**Interfaces:**
- `SignupResult` contains `UserEntity user` and `bool requiresEmailConfirmation`.
- `SignupResultDto` contains `UserDto user` and `bool requiresEmailConfirmation` and maps to `SignupResult`.
- `UserRepositoryDataSource.signUp`, `UserRepository.signUpRepository`, and `UserUseCase.getSignup` return the corresponding typed result.

- [ ] **Step 1: Write the failing result/mapping test**

Test that a `SignupResultDto` with a user and `requiresEmailConfirmation: true` maps to a domain `SignupResult` while preserving the flag and user email. Test the false flag as well.

```dart
test('maps the confirmation-required flag and user to the domain result', () {
  final result = SignupResultDto(
    user: UserDto(email: 'student@example.com'),
    requiresEmailConfirmation: true,
  ).toEntity();

  expect(result.requiresEmailConfirmation, isTrue);
  expect(result.user.email, 'student@example.com');
});
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test --no-pub test/domain/entities/api/auth/signup_result_test.dart`

Expected: FAIL because the result types and mapper do not exist.

- [ ] **Step 3: Implement the typed result and layer mappings**

Add immutable result classes and update the repository contracts. In `UserRemoteDatasource.signUp`, build metadata from `dto.toJson()` after removing `password` and `token`, call `supabaseAuth.signUp`, throw `AuthException('Unable to create the account.')` if Supabase returns no user, and return `_fromUserMetadata(auth.user, dto)` with `requiresEmailConfirmation: auth.session == null`. Remove the catch-all that returns an empty `UserDto`; let Supabase exceptions propagate.

Also update `UserDto.fromEntity` to preserve `courseId` when an entity has one.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `flutter test --no-pub test/domain/entities/api/auth/signup_result_test.dart`

Expected: PASS.

---

### Task 3: Make signup and login forms show correct feedback and navigation

**Files:**
- Modify: `lib/presentation/provider/auth/event/auth_state_provider.dart:98-130`
- Modify: `lib/presentation/widgets/forms/signup_form.dart:1-145`
- Modify: `lib/presentation/widgets/forms/login_form.dart:1-110`
- Test: `test/presentation/provider/auth/signup_submission_test.dart` (temporary; delete after verification)

**Interfaces:**
- `LoginNotifier.submitSignup()` returns `Future<SignupResult?>`; `null` means the notifier stored a user-facing error in `LoginFormState.errorMessage`.
- Signup clears its controllers only after a non-null result.

- [ ] **Step 1: Write the failing provider behavior test**

Add a test around the notifier's real success/failure contract using a fake `UserUseCase` override. The fake must subclass `UserUseCase`, call `super` with `UserRepositoryImpl(datasource: UserRemoteDatasource())`, and override `getSignup` to return a supplied `SignupResult` or throw a supplied `AuthException`. Override `userUseCaseProvider` in a `ProviderContainer`, populate the notifier's first-name controller, and assert both result and controller behavior.

```dart
class _FakeUserUseCase extends UserUseCase {
  _FakeUserUseCase({this.result, this.failure})
      : super(impl: UserRepositoryImpl(datasource: UserRemoteDatasource()));

  final SignupResult? result;
  final AuthException? failure;

  @override
  Future<SignupResult> getSignup(UserEntity entity) async {
    if (failure != null) throw failure!;
    return result!;
  }
}

test('confirmation-required signup returns a result and clears fields', () async {
  final container = ProviderContainer(
    overrides: [
      userUseCaseProvider.overrideWithValue(
        _FakeUserUseCase(
          result: SignupResult(
            user: UserEntity(email: 'student@example.com'),
            requiresEmailConfirmation: true,
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  final notifier = container.read(loginFormProvider.notifier);
  notifier.firstNameController.text = 'Ana';

  final result = await notifier.submitSignup();

  expect(result?.requiresEmailConfirmation, isTrue);
  expect(notifier.firstNameController.text, isEmpty);
});

test('failed signup returns null and preserves fields', () async {
  final container = ProviderContainer(
    overrides: [
      userUseCaseProvider.overrideWithValue(
        _FakeUserUseCase(failure: AuthException('Email already registered')),
      ),
    ],
  );
  addTearDown(container.dispose);

  final notifier = container.read(loginFormProvider.notifier);
  notifier.firstNameController.text = 'Ana';

  final result = await notifier.submitSignup();

  expect(result, isNull);
  expect(notifier.firstNameController.text, 'Ana');
  expect(container.read(loginFormProvider).errorMessage, 'Email already registered');
});
```

The test must fail against the current `Future<void>` notifier because it cannot return a `SignupResult` and because the failure path currently clears fields after the datasource converts errors to an empty result.

- [ ] **Step 2: Run the test and verify it fails for the missing behavior**

Run: `flutter test --no-pub test/presentation/provider/auth/signup_submission_test.dart`

Expected: FAIL until the typed result and provider contract are available.

- [ ] **Step 3: Implement the notifier and form flow**

In `submitSignup`, await `useCase.getSignup`, clear signup controllers only after success, return the result, and return `null` from both catch branches after storing the error. In `SignupForm`, after validation, inspect the returned result and current state: show `AppToast.showInfo` plus navigate to login for confirmation-required signup; show `AppToast.showSuccess` plus navigate to main for an immediate session; show `AppToast.showError` without clearing fields when the result is null.

In `LoginForm`, show an error toast from `errorMessage` when `submit()` returns false and a success toast followed by `context.go(RouteConstants.main)` when it returns true. Replace both provider-preview direct snackbars with `AppToast.showInfo`.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `flutter test --no-pub test/presentation/provider/auth/signup_submission_test.dart`

Expected: PASS.

---

### Task 4: Correct auth routing and mobile email callback configuration

**Files:**
- Modify: `lib/core/constants/routers/app_router.dart:234-258`
- Modify: `lib/const.dart`
- Modify: `lib/data/data_source/auth/user_remote_datasource.dart:76-84`
- Modify: `ios/Runner/Info.plist`
- Test: `test/core/constants/routers/auth_redirect_test.dart` (temporary; delete after verification)

**Interfaces:**
- Add a pure `authRedirect({required bool isLoggedIn, required String location})` function for deterministic routing tests.
- `_redirectForAuth` computes `session != null && !session.isExpired` and delegates to `authRedirect`.

- [ ] **Step 1: Write the failing redirect tests**

Cover these decisions:

```dart
test('logged-out protected route redirects to login', () {
  expect(
    authRedirect(isLoggedIn: false, location: RouteConstants.main),
    RouteConstants.login,
  );
});

test('logged-out signup route remains available', () {
  expect(
    authRedirect(isLoggedIn: false, location: RouteConstants.signUp),
    isNull,
  );
});

test('logged-in signup route redirects to main', () {
  expect(
    authRedirect(isLoggedIn: true, location: RouteConstants.signUp),
    RouteConstants.main,
  );
});
```

Also test that forgot-password remains available for either session state and that an expired session is treated as logged out by the private router adapter's pure input.

- [ ] **Step 2: Run the tests and verify they fail**

Run: `flutter test --no-pub test/core/constants/routers/auth_redirect_test.dart`

Expected: FAIL because the pure helper does not exist and current redirect behavior is inverted.

- [ ] **Step 3: Implement routing and callback configuration**

Define `supabaseAuthRedirectUrl = 'achievia://callback'` in `lib/const.dart`, pass it as `emailRedirectTo`, and add `achievia` under `CFBundleURLSchemes` in iOS `Info.plist`. Keep the existing Android `achievia://callback` intent filter. Implement the pure redirect helper with guest routes `onboarding`, `login`, and `signUp`; allow `forgotPassword` for both states; redirect logged-out protected paths to login; and redirect logged-in guest auth paths to main.

- [ ] **Step 4: Run the focused tests and verify they pass**

Run: `flutter test --no-pub test/core/constants/routers/auth_redirect_test.dart`

Expected: PASS.

---

### Task 5: Migrate all project feedback calls to AppToast

**Files:**
- Modify: `lib/presentation/provider/auth/password_reset/event/reset_password_event.dart:1-199`
- Modify: `lib/presentation/screens/main/messages_screen.dart:116-123`
- Modify: `lib/presentation/screens/screen_contents/contents/new_reminder_screen.dart`
- Modify: `lib/presentation/screens/screen_contents/contents/today_screen.dart`
- Modify: `lib/presentation/screens/screen_contents/contents/reminder_screen_content.dart`
- Modify: `lib/presentation/widgets/cards/mantra_card.dart`
- Modify: `lib/presentation/widgets/list_items/medical_abbreviation_list.dart`

**Interfaces:**
- No direct `ScaffoldMessenger.of(context).showSnackBar` calls remain outside `snack_bar_utils.dart`.
- Existing `SnackBarUtils.show*` callers use `AppToast.show*` with the same semantic messages.

- [ ] **Step 1: Write the failing source-inventory assertion**

Create a temporary Dart test that reads the `lib` source tree and fails while direct snackbar construction or `SnackBarUtils.show` references remain outside the helper. The test must exclude the helper itself and assert that the final source contains the `AppToast` class.

```dart
test('feedback construction is centralized in AppToast', () {
  final lib = Directory('lib');
  final dartFiles = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));

  final nonHelperSource = dartFiles
      .where((file) => !file.path.endsWith('snack_bar_utils.dart'))
      .map((file) => file.readAsStringSync())
      .join('\n');

  expect(nonHelperSource, isNot(contains('SnackBar(')));
  expect(nonHelperSource, isNot(contains('SnackBarUtils.show')));
});
```

- [ ] **Step 2: Run the inventory test and verify it fails**

Run: `flutter test --no-pub test/core/utils/feedback_inventory_test.dart`

Expected: FAIL because direct snackbar and old helper references currently exist.

- [ ] **Step 3: Replace direct calls and retain persistent UI**

Update imports and calls in all listed files. Use `AppToast.showError` for password-reset and chat-opening failures, `AppToast.showSuccess` for existing successful reminder/task/mantra actions, `AppToast.showWarning` for missing reminder titles, and `AppToast.showInfo` for the medical abbreviation and Google provider-preview messages. Add a success toast after a password change and an info/success toast after a reset email is sent only where the operation currently has no other success feedback. Do not replace dialogs or `AsyncValue` error widgets.

- [ ] **Step 4: Run the inventory test and verify it passes**

Run: `flutter test --no-pub test/core/utils/feedback_inventory_test.dart`

Expected: PASS, with `SnackBar` construction isolated to `snack_bar_utils.dart`.

---

### Task 6: Repair the profile migration and verify the implementation

**Files:**
- Modify: `supabase/migrations/20260601171702_users.sql:7-12,70-114`
- Test: `test/supabase/registration_migration_test.dart` (temporary; delete after verification)

**Interfaces:**
- The migration remains compatible with the current `public.profiles` table, constraints, RLS policies, and `handle_new_user` trigger.

- [ ] **Step 1: Write the failing migration test**

Read the migration and assert it contains a closed first `create table` statement before the first trigger statement, exactly one policy body for each of select/insert/update/delete, and the `handle_new_user` trigger. The initial test must fail against the current malformed file.

```dart
test('profile migration has complete statements and one policy body per action', () {
  final sql = File('supabase/migrations/20260601171702_users.sql').readAsStringSync();

  expect(sql, contains('created_at timestamp with time zone default now()\n);'));
  expect(RegExp(r'create policy "Users can read').allMatches(sql), hasLength(1));
  expect(RegExp(r'create policy "Users can insert').allMatches(sql), hasLength(1));
  expect(RegExp(r'create policy "Users can update').allMatches(sql), hasLength(1));
  expect(RegExp(r'create policy "Users can delete').allMatches(sql), hasLength(1));
  expect(
    RegExp(r'^\s*on public\\.profiles\s*$', multiLine: true).allMatches(sql),
    hasLength(4),
  );
  expect(sql, contains('create trigger on_auth_user_created'));
});
```

- [ ] **Step 2: Run the migration test and verify it fails**

Run: `flutter test --no-pub test/supabase/registration_migration_test.dart`

Expected: FAIL because the opening table statement and duplicate policy fragments are malformed.

- [ ] **Step 3: Make the smallest SQL correction**

Add the missing `);` after the initial table columns and remove the dangling duplicate policy clauses that follow each complete policy. Leave table columns, constraints, trigger body, and RLS expressions unchanged.

- [ ] **Step 4: Run the migration test and verify it passes**

Run: `flutter test --no-pub test/supabase/registration_migration_test.dart`

Expected: PASS.

- [ ] **Step 5: Run final source and project verification**

Run each command and record its actual exit status:

```powershell
flutter test --no-pub
flutter analyze --no-pub
flutter build windows --debug
git diff --check
rg -n --glob '*.dart' 'SnackBar\(|SnackBarUtils\.' lib
```

Expected: the tests, analyzer, build, and diff check exit successfully; the final `rg` result contains only the centralized helper's `SnackBar` construction and no `SnackBarUtils` references. If Flutter tooling hangs again, report the exact command and bounded timeout instead of claiming it passed.

- [ ] **Step 6: Delete only task-created temporary tests**

Delete the temporary test files listed in Tasks 1-6 with `apply_patch`. Re-run `git status --short` and confirm no pre-existing test file was deleted or modified.

- [ ] **Step 7: Update Graphify after verification**

From `C:\Users\lNooisYl\Documents\IT\FLUTTER\achievia_folder`, run the Graphify incremental update for the current project so the graph reflects the changed auth, routing, feedback, platform, and migration files. Do not commit or push generated graph outputs.
