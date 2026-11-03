# Achievia — Changelog

> **Session date:** September 26, 2026  
> **Author:** Kiro AI  
> **Status:** All changes are local (Flutter code only). See [Supabase Action Checklist](#supabase-action-checklist) at the bottom for required database changes.

---

## Summary of All Fixes

| # | Area | What was wrong | What was fixed |
|---|---|---|---|
| 1 | Pomodoro Timer | "Comfort music" section visible | Removed the section from the screen |
| 2 | Profile ID Card — PURPOSE | Showed N/A for all users | Hard-coded `MTLE` at signup; auto-patch for existing users |
| 3 | Profile ID Card — UNIVERSITY | Showed N/A; field never collected | Added University/School field to signup form |
| 4 | About → Achievia tab — Logo meanings | 4 out of 5 logo descriptions were empty | Filled in all descriptions |
| 5 | About → Achievia tab — Mission/Vision | Section didn't exist | Added Mission, Vision & Core Values section |
| 6 | Home → Today's Achievian Goal | Always showed "No goal set for today" even with tasks set | Connected tasks to goal widget as fallback; fixed date filter to include overdue tasks |
| 7 | Reminders — date toggle ignored | Turning off date toggle still saved the selected date | Fixed `_handleSave` to use today when date is disabled |
| 8 | Mother Notes | "No modules found" — never showed content | Removed wrong `user_id` filter; added missing RLS migration |
| 9 | Progress — This month's streak | Showed current running streak instead of longest streak in the month | Fixed to use longest consecutive run within the current calendar month |
| 10 | Profile — Days left before Board Exam | Showed "Today" even when exam is tomorrow | Normalized both dates to midnight before computing difference |

---

## Detailed Fix Log

---

### Fix 1 — Pomodoro Timer: Remove Comfort Music Section

**File changed:**
- `lib/presentation/screens/settings/pomodoro_timer/pomodoro_timer_screen.dart`

**What was wrong:**  
The "Comfort music" section (with Pomodoro Music, Review music, Break time music toggles) was visible on the Pomodoro Timer screen. Per design requirement, this section should be removed.

**What was changed:**  
Removed `PomodoroComfortMusicSection()` widget and its `SizedBox(height: 16)` spacer from the screen. Also removed the now-unused import for `pomodoro_comfort_music_section.dart`.

---

### Fix 2 — Profile ID Card: PURPOSE shows N/A

**Files changed:**
- `lib/presentation/provider/auth/event/auth_state_provider.dart`
- `lib/data/data_source/profile/profile_remote_datasource.dart`
- `lib/data/repositoryImpl/profile/profile_repository_impl.dart`
- `lib/domain/repository/profile/profile_repository.dart`
- `lib/domain/use_cases/profile/profile_use_case.dart`
- `lib/presentation/provider/profile/profile_provider.dart`

**What was wrong:**  
`purpose` was never sent during signup — the `UserEntity` in `submitSignup()` had no `purpose` field. Supabase stored `null`, and `_safeUpper(null)` returned `'N/A'` on the ID card. Existing accounts already had `null` in the database.

**What was changed:**
1. `auth_state_provider.dart` — Added `purpose: 'MTLE'` to the `UserEntity` in `submitSignup()`. PURPOSE is fixed for all users (MTLE = Medical Technology Licensure Examination), so it is set programmatically, not via a UI field.
2. `profile_remote_datasource.dart` — Added `updatePurpose(String purpose)` method.
3. `profile_repository.dart` + `profile_repository_impl.dart` + `profile_use_case.dart` — Wired `updatePurpose` through the full stack.
4. `profile_provider.dart` — `profileProvider` now auto-patches `purpose` to `'MTLE'` on first load if the DB value is null/empty. Returns the corrected entity immediately so the UI shows the correct value without a second fetch.

> ⚠️ Only fixes display for new signups and existing users on next app open. Users who never open the app again will still have null in DB.

---

### Fix 3 — Profile ID Card: UNIVERSITY shows N/A

**Files changed:**
- `lib/presentation/widgets/forms/signup_form.dart`

**What was wrong:**  
`schoolController` existed in the provider and was already wired to `university` in `submitSignup()`, but the signup form UI never rendered an input field for it. So `schoolController.text` was always empty at signup → `null` stored in Supabase → `'N/A'` on the ID card.

**What was changed:**  
Added a `ReusableField` bound to `loginNotifier.schoolController` in `SignupForm`, placed between the Username and Email fields. Label: "University / School". Includes validation.

> ⚠️ Only fixes new signups. Existing accounts need a profile edit screen to update their university.

---

### Fix 4 — About → Achievia: Logo Meaning descriptions empty

**File changed:**
- `lib/presentation/widgets/list_items/logo_meaning_section.dart`

**What was wrong:**  
4 of the 5 expandable logo items had `description: ''` — tapping them expanded to a blank space.

**What was changed:**  
Added full descriptions for all 4 items:
- **Peak** — highest point of achievement, board exam passers as peak performers
- **Ups and Downs** — wave pattern reflecting the reality of every student's journey
- **Mistakes and Curiosity** — X mark reframed as courage to try and learn from errors
- **Corrections and Improvements** — checkmark representing continuous growth and review

---

### Fix 5 — About → Achievia: Add Mission, Vision & Core Values

**Files added/changed:**
- `lib/presentation/widgets/list_items/mission_vision_section.dart` *(new)*
- `lib/presentation/provider/about/about_provider.dart`
- `lib/presentation/screens/screen_contents/contents/achievia_content_screen.dart`

**What was wrong:**  
The Achievia tab had no Mission, Vision, or Core Values section.

**What was changed:**
1. Created `MissionVisionSection` widget — three expandable cards (Mission, Vision, Core Values) using the same design pattern as the logo items.
2. Core Values expands into 6 items with icons: Excellence, Integrity, Innovation, Community, Accessibility, Growth Mindset.
3. Added `mvcExpandableItemsProvider` to `about_provider.dart` for independent expand/collapse state.
4. Added `MissionVisionSection` to `AchieviaContentScreen` between the intro card and the logo section.

---

### Fix 6 — Home: "Today's Achievian Goal" always shows "No goal set for today"

**Files changed:**
- `lib/presentation/provider/task/task_provider.dart`
- `lib/presentation/screens/main/home_screen.dart`

**What was wrong:**  
"Today's Achievian Goal" on the home screen reads from a dedicated `goals` Supabase table (a separate feature). The user's tasks live in the `tasks` table — the two systems were never connected. Even with a task set for today, the home screen showed "No goal set for today".

Additionally, `tasksProvider` was not `.autoDispose`, so it cached data forever and never refreshed.

The `todayTasksProvider` filter was also **too strict** — it only matched tasks with deadline == today exactly. A task set for September 25 would be invisible on September 26 even if not yet completed.

**What was changed:**
1. `task_provider.dart`:
   - `tasksProvider` → changed to `FutureProvider.autoDispose` so it re-fetches on every screen mount.
   - `todayTasksProvider` → added as a new derived provider. Filter changed from exact-date to **deadline ≤ end of today AND not done** (includes overdue tasks). Sorted ascending by deadline.
2. `home_screen.dart`:
   - Added `_TodayGoalSection` widget implementing a priority chain:
     1. Dedicated `goals` table row → show `GoalCard` (original behavior preserved)
     2. No dedicated goal → fall back to today's + overdue tasks from `tasksProvider`
     3. Neither → "No goal set for today"
   - Task cards use `markTaskDoneProvider` — tapping marks the task done in Supabase and refreshes both the home screen and the Tasks tab.

---

### Fix 7 — Reminders: Date toggle ignored on save

**File changed:**
- `lib/presentation/screens/screen_contents/contents/new_reminder_screen.dart`

**What was wrong:**  
`NewReminderScreen` had an `_isDateEnabled` toggle but `_handleSave()` always used `_selectedDate` regardless of the toggle state.

**What was changed:**  
`_handleSave()` now uses `DateTime.now()` as the base date when `_isDateEnabled` is false, instead of always using `_selectedDate`.

---

### Fix 8 — Mother Notes: "No modules found"

**Files changed:**
- `lib/data/data_source/reviewer/module_remote_datasource.dart`
- `lib/data/repositoryImpl/reviewer/module_repository_impl.dart`

**File added:**
- `supabase/migrations/20260930000000_create_modules_table.sql` *(new — must be run in Supabase)*

**What was wrong:**  
Two root causes:

1. **Wrong query filter** — `ModuleRemoteDatasource` filtered with `.eq('user_id', userId)`. But `modules` is admin/teacher-created content, not user-owned. No module row will ever match a regular user's UUID → always returns `[]` silently → "No modules found".

2. **Missing RLS policy** — No `CREATE TABLE` migration for `modules` existed in the repo (it was created manually in Supabase dashboard). Without a tracked RLS `SELECT` policy allowing authenticated users to read rows, Supabase silently returns empty array.

3. **Offline path misleading** — When offline, the repository returned an empty list silently, making it appear like there were no modules instead of showing a connectivity error.

**What was changed:**
1. `module_remote_datasource.dart`:
   - Removed `SupabaseUserContext` dependency entirely.
   - Replaced `.eq('user_id', userId)` with `.eq('status', 'active')` — correct filter for shared content.
   - Removed the second `totalRows` count query (was an unnecessary extra network round-trip).
   - Fixed `_normalizeModule` fallback types — `userId` and `createdAt` always produce strings, `subjectId` always produces int.
2. `module_repository_impl.dart`:
   - Changed offline path to **throw** instead of returning empty — UI now shows retry button instead of false "No modules found".
   - Replaced `print()` with `debugPrint()`.
3. **New migration** `20260930000000_create_modules_table.sql`:
   - Creates `modules` table (idempotent — safe to run even if table already exists).
   - RLS: `SELECT` open to all authenticated users where `status = 'active'`.
   - `INSERT`/`UPDATE` scoped to the content author.
   - Indexes on `(status, created_at desc, id desc)` and `(subject_id, status)`.

> ⚠️ **Must run the migration in Supabase.** See checklist below.

---

### Fix 9 — Progress: "This month's streak" shows wrong value

**File changed:**
- `lib/core/utils/progress_aggregator.dart`

**What was wrong:**  
`thisMonthStreak` used `_currentStreak(activeKeys, today)` — walks backward from today counting consecutive days with no month boundary. So if the user had a 2-day streak on Sep 10–11 but took a break on Sep 12, `_currentStreak` returns 0 (or the length of whatever current run exists) instead of `2` (the longest run within the month).

**What was changed:**  
Replaced `_currentStreak` call with `_longestStreakInMonth` — applies the existing `_longestStreak` function to only the days within the current calendar month. Removed the now-unused `_currentStreak` function.

```
Before: thisMonthStreak = _currentStreak(activeKeys, today)
After:  thisMonthStreak = _longestStreakInMonth(days filtered to current month)
```

`longestStreak` was already correct (all-time longest consecutive run) — not changed.

---

### Fix 10 — Profile: "Days left before Board Exam" shows "Today" incorrectly

**File changed:**
- `lib/presentation/provider/profile/profile_view_state.dart`

**What was wrong:**  
`_calculateDaysLeft` computed `examDate.difference(DateTime.now()).inDays`. `DateTime.now()` includes the current time. If the exam date is stored as midnight Sep 26 and the current time is Sep 25 at 11 PM, the difference is only ~1 hour → `inDays` truncates to `0` → shows "Today" even though the exam is tomorrow.

**What was changed:**  
Both `examDate` and `now` are normalized to midnight (`DateTime(y, m, d)`) before computing the difference. Now the comparison is purely calendar-date based regardless of time of day.

---

## Supabase Action Checklist

> These are database-level changes that **must be applied manually** in your Supabase project. Flutter code changes alone are not enough for some fixes.

### 🔴 Required — App will not work correctly without these

#### 1. Run the modules table migration

The `modules` table needs RLS policies so authenticated users can read active modules. Without this, Mother Notes will always show empty.

**Option A — Supabase CLI (recommended):**
```bash
supabase db push
```

**Option B — Supabase Dashboard → SQL Editor:**  
Copy and run the contents of:
```
supabase/migrations/20260930000000_create_modules_table.sql
```

> If the `modules` table was already created manually in the dashboard, this migration is safe — it uses `CREATE TABLE IF NOT EXISTS` and `DROP POLICY IF EXISTS`. It will only add the missing RLS policies without destroying existing data.

---

### 🟡 Recommended — Fixes data for existing users

#### 2. Patch existing users' PURPOSE to MTLE

New signups will automatically get `purpose = 'MTLE'` via the Flutter fix. But existing users already have `null` in the database. The Flutter auto-patch in `profileProvider` will fix it on next app open, but if you want to bulk-fix all existing rows now:

```sql
update public.profiles
set purpose = 'MTLE'
where purpose is null or trim(purpose) = '';
```

Run in: Supabase Dashboard → SQL Editor

---

#### 3. Verify the tasks table has RLS enabled

The migration `20260603011346_add_tasks_table.sql` defines the `tasks` table with RLS. Confirm it was applied:

```sql
-- Check RLS is enabled
select relname, relrowsecurity
from pg_class
where relname = 'tasks' and relnamespace = 'public'::regnamespace;

-- Check policies exist
select policyname, cmd
from pg_policies
where tablename = 'tasks' and schemaname = 'public';
```

Expected result: `relrowsecurity = true`, and policies for `SELECT`, `INSERT`, `UPDATE` should exist. If missing, re-run the migration manually.

---

#### 4. Seed some active modules (so Mother Notes shows content)

The `modules` table likely has no rows, or rows belong to admin `user_id`s. After running the migration and confirming RLS is set, insert at least one test module:

```sql
insert into public.modules (title, description, status, subject_id)
values
  ('Parasitology — Protozoa', 'Covers intestinal protozoa, blood protozoa, and tissue protozoa.', 'active', 1),
  ('Parasitology — Helminths', 'Covers cestodes, trematodes, and nematodes.', 'active', 1),
  ('Microbiology — Bacteriology', 'Covers gram-positive and gram-negative organisms.', 'active', 2);
```

Adjust `subject_id` values to match your actual subjects table.

---

### 🟢 Informational — No action needed

- **UNIVERSITY field** — New signups will populate it from the signup form. Existing users need a profile edit screen (not yet built) to update it.
- **Board exam date** — The days-left calculation fix is purely client-side. No DB change needed.
- **Streak calculation** — Purely client-side. No DB change needed.
- **Today's Achievian Goal** — Uses the existing `tasks` table. No DB change needed.
