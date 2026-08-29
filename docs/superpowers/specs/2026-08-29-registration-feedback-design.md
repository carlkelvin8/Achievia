# Registration and Feedback Design

**Status:** Approved for implementation on 2026-08-29

**Goal:** Make email registration behave correctly with the current Supabase project and provide one consistent, reusable toast-style feedback API throughout the Flutter app.

## Context

The app uses `supabase_flutter` v2 and the `public.profiles` table. The live project currently allows email signup and requires email confirmation. Supabase returns a user with a null session when confirmation is required, so a null session is a successful intermediate state rather than an error.

The current client treats that state as an empty result, swallows signup errors, clears the form without feedback, passes a relative `/main` redirect, and has an inverted auth-router predicate. The project already has `SnackBarUtils`; it will become the single feedback implementation instead of adding a dependency or a second notification system.

## Design

### 1. Shared feedback API

Refactor `lib/core/utils/snack_bar_utils.dart` to expose `AppToast` with these methods:

```dart
static void showSuccess(BuildContext context, String message);
static void showError(BuildContext context, String message);
static void showInfo(BuildContext context, String message);
static void showWarning(BuildContext context, String message);
```

Each method will use `ScaffoldMessenger.maybeOf(context)`, dismiss the current message, and show a floating Material `SnackBar` with a semantic color, leading icon, readable duration, and theme-safe text. The API remains context-based so feedback is emitted at the UI boundary, where the user can see and act on it.

Migrate all direct `ScaffoldMessenger`/`SnackBar` calls to `AppToast`:

- login and signup provider-preview buttons;
- signup success, confirmation-required, and failure feedback;
- login success and failure feedback;
- password-reset event failures;
- message/chat-opening failures;
- existing reminder, mantra, task, and medical-abbreviation helper usages.

Inline field validation, modal dialogs, loading indicators, and full-page `AsyncValue` error states remain inline because they provide persistent context that a transient toast cannot replace.

### 2. Signup result and error flow

Introduce a typed `SignupResult` domain value containing the returned user and `requiresEmailConfirmation`. Update the datasource, repository, and use case signatures to return this value.

`UserRemoteDatasource.signUp` will:

1. call Supabase with the email, password, and non-secret profile metadata;
2. reject a missing returned user;
3. return `requiresEmailConfirmation: auth.session == null`;
4. rethrow `AuthException` and other failures so the presentation layer can show the real user-facing error.

The password will not be included in `data` metadata. The signup notifier will return `SignupResult?`, clear fields only after a returned result, and preserve an error message on failure. The form will show:

- an info toast and navigate to login when email confirmation is required;
- a success toast and navigate to the main route when a session is created immediately;
- an error toast without clearing input when signup fails.

### 3. Login and routing

The login form will show an error toast when submission returns false and a success toast before navigating to the main route on success.

Auth routing will derive login state as `session != null && !session.isExpired`, without null assertions. Logged-out users may access onboarding, login, signup, and forgot-password; protected routes redirect to login. Logged-in users are redirected away from onboarding, login, and signup while forgot-password remains available.

### 4. Email confirmation redirect

Use the existing mobile callback URI `achievia://callback` instead of `/main`. Add the corresponding custom URL scheme to iOS; Android already declares the scheme and callback host. `supabase_flutter` v2 will consume auth callback URLs internally.

The Supabase Dashboard must allow `achievia://callback` under Authentication URL Configuration. This repository change will not attempt to alter the remote Dashboard with the public client key.

### 5. Database migration safety

Correct the malformed opening statement and duplicate policy fragments in `20260601171702_users.sql` so a fresh migration run can create the profile table and signup trigger. Preserve the current table names, columns, constraints, RLS behavior, and trigger metadata contract.

## Verification

Create temporary tests first and observe them fail before implementation:

- `AppToast` renders the requested message and semantic style for each public method;
- a confirmed-session signup result is treated as immediate success;
- a null-session signup result is treated as confirmation-required;
- signup failures are returned to the UI instead of being converted into an empty user;
- auth redirect decisions are correct for valid, expired, and absent sessions.

Run the focused tests, the full Flutter test suite, `flutter analyze`, and a platform build check. Search the final source for direct snackbar calls and verify only `AppToast` owns `SnackBar` construction. Do not create or modify a remote user during verification.

## References

- [Supabase Flutter signUp reference](https://supabase.com/docs/reference/dart/auth-signup)
- [Supabase native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
