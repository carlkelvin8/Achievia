# Question Bank Practice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dedicated, course-filtered Question Bank flow with subject/topic selection, up to 20 randomized untimed questions, immediate feedback, saved Supabase attempts, results, and recent progress.

**Architecture:** Add an isolated Question Bank data/repository/provider stack over the existing Supabase `profiles`, `subjects`, `quizzes`, `questions`, and `choices` tables, plus a new owner-scoped `question_bank_attempts` table. Dedicated Riverpod-driven screens reuse the existing app bar, selection card, question renderer, and button components without touching Mock Boards state, timers, caches, or scoring.

**Tech Stack:** Flutter 3/Dart 3.8, Flutter Riverpod 3, GoRouter 17, Supabase Flutter 2, PostgreSQL/RLS, Flutter widget/unit tests.

**Spec:** `docs/superpowers/specs/2026-08-14-question-bank-practice-design.md`

## Global Constraints

- Keep Mock Boards and Pre Boards behavior unchanged.
- Filter subjects strictly with the signed-in profile's `course_id`; never fall back to unrelated subjects.
- Use at most 20 randomized usable questions and use all available questions when fewer than 20 exist.
- Give immediate answer feedback, lock answered choices, and use no timer.
- Store attempts in `question_bank_attempts`, never `quiz_attempts` or mock-board caches.
- Reuse `CustomAppBar`, `ReviewerCategoryCard`, `QuestionsContent`, and `ReusableButton` where their behavior fits.
- Do not add dependencies or generated dependency-injection files.
- Do not commit or push any files. Every task ends with tests and an uncommitted diff inspection.

---

## File Structure

- `supabase/migrations/20260814000000_add_question_bank_attempts.sql`: attempt table, indexes, and owner-only RLS.
- `lib/domain/entities/api/reviewer/question_bank_entity.dart`: subject, topic, selection, attempt, and route argument values.
- `lib/core/utils/question_bank_helpers.dart`: deterministic row mapping, random selection, and score calculation.
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart`: authenticated Supabase reads and attempt insert.
- `lib/domain/repository/questions/question_bank_repository.dart`: testable Question Bank contract.
- `lib/data/repositoryImpl/questions/question_bank_repository_impl.dart`: thin datasource adapter.
- `lib/presentation/provider/reviewer/question_bank_practice_provider.dart`: repository providers, async loaders, and active session state.
- `lib/presentation/screens/question_bank/question_bank_subjects_screen.dart`: course-filtered subjects and recent attempts.
- `lib/presentation/screens/question_bank/question_bank_topics_screen.dart`: topics for one subject.
- `lib/presentation/screens/question_bank/question_bank_practice_screen.dart`: untimed question runner.
- `lib/presentation/screens/question_bank/question_bank_result_screen.dart`: saved result, retry, repeat, and exit actions.
- `lib/presentation/widgets/question_bank/question_bank_status_view.dart`: shared loading/empty/error presentation.
- Existing router, constants, static Question Bank card callback, and focused tests are modified in place.

---

### Task 1: Add the owner-scoped attempt table

**Files:**
- Create: `supabase/migrations/20260814000000_add_question_bank_attempts.sql`
- Create: `test/supabase/question_bank_attempts_migration_test.dart`

**Interfaces:**
- Consumes: existing `public.profiles(id)`, `public.subjects(id)`, `public.quizzes(id)`, and `auth.uid()`.
- Produces: `public.question_bank_attempts` readable/insertable only by its owning authenticated user.

- [ ] **Step 1: Write the failing migration contract test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String migrations() => Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .map((file) => file.readAsStringSync())
      .join('\n')
      .toLowerCase();

  test('question bank attempts store scored topic practice', () {
    final sql = migrations();
    expect(sql, contains('create table if not exists public.question_bank_attempts'));
    expect(sql, contains('correct_answers integer not null'));
    expect(sql, contains('total_questions integer not null'));
    expect(sql, contains('score numeric(5,2) not null'));
    expect(sql, contains('question_bank_attempts_user_completed_idx'));
  });

  test('question bank attempts are owner scoped', () {
    final sql = migrations();
    expect(sql, contains('alter table public.question_bank_attempts enable row level security'));
    expect(sql, contains('using ((select auth.uid()) = user_id)'));
    expect(sql, contains('with check ((select auth.uid()) = user_id)'));
  });
}
```

- [ ] **Step 2: Run the test and confirm the migration is missing**

Run: `flutter test test/supabase/question_bank_attempts_migration_test.dart`

Expected: FAIL because `question_bank_attempts` does not occur in migrations.

- [ ] **Step 3: Add the SQL migration**

```sql
create table if not exists public.question_bank_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_id integer not null references public.subjects(id) on delete cascade,
  quiz_id integer not null references public.quizzes(id) on delete cascade,
  correct_answers integer not null check (correct_answers >= 0),
  total_questions integer not null check (total_questions > 0),
  score numeric(5,2) not null check (score between 0 and 100),
  completed_at timestamptz not null default now(),
  check (correct_answers <= total_questions)
);

create index if not exists question_bank_attempts_user_completed_idx
  on public.question_bank_attempts(user_id, completed_at desc);
create index if not exists question_bank_attempts_user_quiz_idx
  on public.question_bank_attempts(user_id, quiz_id);

alter table public.question_bank_attempts enable row level security;

create policy "Users can read their own question bank attempts"
  on public.question_bank_attempts for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert their own question bank attempts"
  on public.question_bank_attempts for insert to authenticated
  with check ((select auth.uid()) = user_id);
```

- [ ] **Step 4: Run the focused test**

Run: `flutter test test/supabase/question_bank_attempts_migration_test.dart`

Expected: PASS.

- [ ] **Step 5: Inspect without committing**

Run: `git diff --check && git status --short`

Expected: the migration and test are uncommitted with no whitespace errors.

---

### Task 2: Add domain values and deterministic practice helpers

**Files:**
- Create: `lib/domain/entities/api/reviewer/question_bank_entity.dart`
- Create: `lib/core/utils/question_bank_helpers.dart`
- Create: `test/core/utils/question_bank_helpers_test.dart`

**Interfaces:**
- Consumes: `QuestionItemEntity` and `ChoiceEntity` from `quiz_entity.dart`.
- Produces: `QuestionBankSubject`, `QuestionBankTopic`, `QuestionBankSelection`, `QuestionBankAttempt`, route argument values, `buildQuestionBankPracticeQuestions(...)`, and `questionBankScore(...)`.

- [ ] **Step 1: Write failing helper tests**

```dart
test('builds at most 20 usable randomized questions', () {
  final questions = List.generate(25, (i) => {
    'id': i + 1,
    'quiz_id': 7,
    'question_text': 'Question ${i + 1}',
  });
  final choices = List.generate(25, (i) => {
    'id': i + 100,
    'question_id': i + 1,
    'choice_text': 'Answer',
    'is_correct': true,
  });

  final result = buildQuestionBankPracticeQuestions(
    questionRows: questions,
    choiceRows: choices,
    limit: 20,
    random: Random(1),
  );

  expect(result, hasLength(20));
  expect(result.map((q) => q.id).toSet(), hasLength(20));
});

test('drops questions without choices and keeps fewer than 20', () {
  final result = buildQuestionBankPracticeQuestions(
    questionRows: const [
      {'id': 1, 'question_text': 'Usable'},
      {'id': 2, 'question_text': 'No choices'},
    ],
    choiceRows: const [
      {'id': 10, 'question_id': 1, 'choice_text': 'A', 'is_correct': true},
    ],
    random: Random(1),
  );
  expect(result.single.id, 1);
});

test('calculates percentage scores', () {
  expect(questionBankScore(correct: 15, total: 20), 75);
  expect(questionBankScore(correct: 0, total: 0), 0);
});
```

- [ ] **Step 2: Run the helper tests and confirm missing symbols**

Run: `flutter test test/core/utils/question_bank_helpers_test.dart`

Expected: FAIL because the entities and helper functions do not exist.

- [ ] **Step 3: Add immutable domain values**

```dart
class QuestionBankSubject {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final String image;
  const QuestionBankSubject({required this.id, required this.courseId, required this.title, required this.description, required this.image});
}

class QuestionBankTopic {
  final int id;
  final int subjectId;
  final String title;
  final String description;
  const QuestionBankTopic({required this.id, required this.subjectId, required this.title, required this.description});
}

class QuestionBankSelection {
  final QuestionBankSubject subject;
  final QuestionBankTopic topic;
  const QuestionBankSelection({required this.subject, required this.topic});
}

class QuestionBankAttempt {
  final String id;
  final String userId;
  final int subjectId;
  final int topicId;
  final String subjectTitle;
  final String topicTitle;
  final int correctAnswers;
  final int totalQuestions;
  final double score;
  final DateTime completedAt;
  const QuestionBankAttempt({required this.id, required this.userId, required this.subjectId, required this.topicId, required this.subjectTitle, required this.topicTitle, required this.correctAnswers, required this.totalQuestions, required this.score, required this.completedAt});
}

class QuestionBankTopicArgs {
  final QuestionBankSubject subject;
  const QuestionBankTopicArgs(this.subject);
}

class QuestionBankPracticeArgs {
  final QuestionBankSelection selection;
  const QuestionBankPracticeArgs(this.selection);
}

class QuestionBankResultArgs {
  final QuestionBankSelection selection;
  final QuestionBankAttempt attempt;
  final bool isSaved;
  const QuestionBankResultArgs({required this.selection, required this.attempt, required this.isSaved});
}

class QuestionBankCompletion {
  final QuestionBankAttempt attempt;
  final bool isSaved;
  const QuestionBankCompletion({required this.attempt, required this.isSaved});
}
```

- [ ] **Step 4: Implement row mapping, grouping, filtering, shuffling, limiting, and score calculation**

```dart
List<QuestionItemEntity> buildQuestionBankPracticeQuestions({
  required List<Map<String, dynamic>> questionRows,
  required List<Map<String, dynamic>> choiceRows,
  int limit = 20,
  Random? random,
}) {
  final grouped = <int, List<ChoiceEntity>>{};
  for (final row in choiceRows) {
    final questionId = readInt(row['question_id'] ?? row['questionId']);
    if (questionId == null) continue;
    grouped.putIfAbsent(questionId, () => []).add(ChoiceEntity(
      id: readInt(row['id']) ?? 0,
      questiondId: questionId,
      choiceText: (row['choice_text'] ?? row['choiceText'] ?? '').toString(),
      isCorrect: row['is_correct'] == true,
    ));
  }
  final usable = questionRows.map((row) {
    final id = readInt(row['id']);
    if (id == null || (grouped[id] ?? const []).isEmpty) return null;
    return QuestionItemEntity(
      id: id,
      questionText: (row['question_text'] ?? row['questionText'] ?? '').toString(),
      choices: grouped[id]!,
    );
  }).whereType<QuestionItemEntity>().toList();
  usable.shuffle(random ?? Random());
  return usable.take(limit).toList();
}

double questionBankScore({required int correct, required int total}) =>
    total == 0 ? 0 : double.parse(((correct / total) * 100).toStringAsFixed(2));
```

- [ ] **Step 5: Run tests and analyze the new files**

Run: `flutter test test/core/utils/question_bank_helpers_test.dart`

Run: `dart analyze lib/domain/entities/api/reviewer/question_bank_entity.dart lib/core/utils/question_bank_helpers.dart`

Expected: PASS and no analyzer issues.

- [ ] **Step 6: Inspect without committing**

Run: `git diff --check && git status --short`

---

### Task 3: Add the Supabase datasource and repository contract

**Files:**
- Create: `lib/data/data_source/reviewer/question_bank_remote_datasource.dart`
- Create: `lib/domain/repository/questions/question_bank_repository.dart`
- Create: `lib/data/repositoryImpl/questions/question_bank_repository_impl.dart`
- Create: `test/data/repository/question_bank_repository_impl_test.dart`

**Interfaces:**
- Consumes: Task 2 entities/helpers and `SupabaseUserContext.currentUserId()`.
- Produces: `QuestionBankRepository` with course subjects, topics, practice questions, attempt save, and recent attempt methods.

- [ ] **Step 1: Write a failing repository delegation test with a fake datasource**

```dart
class FakeQuestionBankDataSource implements QuestionBankDataSource {
  int? requestedCourseId;
  @override
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId) async {
    requestedCourseId = courseId;
    return const [QuestionBankSubject(id: 2, courseId: 9, title: 'Hematology', description: '', image: '')];
  }
  @override
  Future<List<QuestionBankTopic>> getTopics(int subjectId) async => const [];
  @override
  Future<List<QuestionItemEntity>> getPracticeQuestions(int quizId, {int limit = 20, Random? random}) async => const [];
  @override
  Future<QuestionBankAttempt> saveAttempt({required QuestionBankSelection selection, required int correctAnswers, required int totalQuestions}) async => QuestionBankAttempt(
    id: 'attempt-1', userId: 'user-1', subjectId: selection.subject.id,
    topicId: selection.topic.id, subjectTitle: selection.subject.title,
    topicTitle: selection.topic.title, correctAnswers: correctAnswers,
    totalQuestions: totalQuestions,
    score: questionBankScore(correct: correctAnswers, total: totalQuestions),
    completedAt: DateTime.utc(2026, 8, 14),
  );
  @override
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5}) async => const [];
}

test('repository requests subjects for the supplied course only', () async {
  final source = FakeQuestionBankDataSource();
  final repository = QuestionBankRepositoryImpl(source);
  final result = await repository.getSubjectsForCourse(9);
  expect(source.requestedCourseId, 9);
  expect(result.single.title, 'Hematology');
});
```

- [ ] **Step 2: Run the repository test and confirm missing contracts**

Run: `flutter test test/data/repository/question_bank_repository_impl_test.dart`

Expected: FAIL because the datasource/repository types do not exist.

- [ ] **Step 3: Define the repository and datasource interfaces**

```dart
abstract class QuestionBankRepository {
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId);
  Future<List<QuestionBankTopic>> getTopics(int subjectId);
  Future<List<QuestionItemEntity>> getPracticeQuestions(int quizId, {int limit = 20, Random? random});
  Future<QuestionBankAttempt> saveAttempt({required QuestionBankSelection selection, required int correctAnswers, required int totalQuestions});
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5});
}

abstract class QuestionBankDataSource {
  Future<List<QuestionBankSubject>> getSubjectsForCourse(int courseId);
  Future<List<QuestionBankTopic>> getTopics(int subjectId);
  Future<List<QuestionItemEntity>> getPracticeQuestions(int quizId, {int limit = 20, Random? random});
  Future<QuestionBankAttempt> saveAttempt({required QuestionBankSelection selection, required int correctAnswers, required int totalQuestions});
  Future<List<QuestionBankAttempt>> getRecentAttempts({int limit = 5});
}
```

- [ ] **Step 4: Implement authenticated Supabase queries**

```dart
final subjects = await _supabase
    .from('subjects')
    .select('id, title, course_id, description, image')
    .eq('course_id', courseId)
    .order('title');

final topics = await _supabase
    .from('quizzes')
    .select('id, title, subject_id, description')
    .eq('subject_id', subjectId)
    .order('title');

final questionRows = await _supabase
    .from('questions')
    .select('id, quiz_id, question_text')
    .eq('quiz_id', quizId);
final questionIds = questionRows.map((row) => readInt(row['id'])).whereType<int>().toList();
final choiceRows = questionIds.isEmpty
    ? <Map<String, dynamic>>[]
    : (await _supabase
        .from('choices')
        .select('id, question_id, choice_text, is_correct')
        .inFilter('question_id', questionIds)
        .order('id'))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
```

For `saveAttempt`, call `SupabaseUserContext.currentUserId()`, insert owner and score fields, select the inserted row, and combine it with labels from `QuestionBankSelection`. For recent attempts, select the latest five rows with `subjects(title)` and `quizzes(title)` embeddings and map missing labels to `Unknown subject`/`Unknown topic`.

- [ ] **Step 5: Run repository and helper tests**

Run: `flutter test test/data/repository/question_bank_repository_impl_test.dart test/core/utils/question_bank_helpers_test.dart`

Expected: PASS.

- [ ] **Step 6: Inspect without committing**

Run: `git diff --check && git status --short`

---

### Task 4: Add Riverpod loaders and active practice state

**Files:**
- Create: `lib/presentation/provider/reviewer/question_bank_practice_provider.dart`
- Create: `test/presentation/provider/reviewer/question_bank_practice_provider_test.dart`

**Interfaces:**
- Consumes: `profileProvider`, `QuestionBankRepository`, and Task 2 domain values.
- Produces: `questionBankRepositoryProvider`, `questionBankSubjectsProvider`, `questionBankTopicsProvider`, `questionBankQuestionsProvider`, `recentQuestionBankAttemptsProvider`, and `questionBankSessionProvider`.

- [ ] **Step 1: Write failing provider/session tests using repository overrides**

```dart
test('subjects provider uses the profile course id', () async {
  final fake = FakeQuestionBankRepository();
  final container = ProviderContainer(overrides: [
    profileProvider.overrideWith((ref) async => const ProfileEntity(courseId: 4)),
    questionBankRepositoryProvider.overrideWithValue(fake),
  ]);
  addTearDown(container.dispose);
  await container.read(questionBankSubjectsProvider.future);
  expect(fake.requestedCourseId, 4);
});

test('session locks one answer and advances after an answer', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(questionBankSessionProvider.notifier);
  notifier.start(selection: selection, questions: questions);
  notifier.answer(1);
  notifier.answer(0);
  expect(container.read(questionBankSessionProvider).selectedAnswers[questionId], 1);
  expect(notifier.next(), isTrue);
});
```

- [ ] **Step 2: Run tests and confirm providers are missing**

Run: `flutter test test/presentation/provider/reviewer/question_bank_practice_provider_test.dart`

Expected: FAIL on missing providers/session types.

- [ ] **Step 3: Implement repository and async providers**

```dart
final questionBankRepositoryProvider = Provider<QuestionBankRepository>((ref) {
  return QuestionBankRepositoryImpl(QuestionBankRemoteDatasource());
});

final questionBankSubjectsProvider = FutureProvider((ref) async {
  final profile = await ref.watch(profileProvider.future);
  final courseId = profile.courseId;
  if (courseId == null) throw const QuestionBankCourseMissingException();
  return ref.read(questionBankRepositoryProvider).getSubjectsForCourse(courseId);
});

final questionBankTopicsProvider = FutureProvider.family<List<QuestionBankTopic>, int>(
  (ref, subjectId) => ref.read(questionBankRepositoryProvider).getTopics(subjectId),
);

final questionBankQuestionsProvider = FutureProvider.family<List<QuestionItemEntity>, int>(
  (ref, quizId) => ref.read(questionBankRepositoryProvider).getPracticeQuestions(quizId),
);

final recentQuestionBankAttemptsProvider = FutureProvider<List<QuestionBankAttempt>>(
  (ref) => ref.read(questionBankRepositoryProvider).getRecentAttempts(limit: 5),
);
```

Keep the missing-course exception typed so the subject screen can show the intended message.

- [ ] **Step 4: Implement the auto-disposed session notifier**

```dart
class QuestionBankSessionState {
  final QuestionBankSelection? selection;
  final List<QuestionItemEntity> questions;
  final int currentIndex;
  final Map<int, int> selectedAnswers;
  final int correctAnswers;
  final bool isSubmitting;
  final Object? saveError;
  const QuestionBankSessionState({
    this.selection,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.correctAnswers = 0,
    this.isSubmitting = false,
    this.saveError,
  });
}

class QuestionBankSessionNotifier extends Notifier<QuestionBankSessionState> {
  @override
  QuestionBankSessionState build() => const QuestionBankSessionState();
  void start({required QuestionBankSelection selection, required List<QuestionItemEntity> questions});
  void answer(int choiceIndex);
  bool next();
  Future<QuestionBankCompletion> complete();
  Future<QuestionBankCompletion> retrySave();
}

final questionBankSessionProvider = NotifierProvider.autoDispose<
    QuestionBankSessionNotifier, QuestionBankSessionState>(
  QuestionBankSessionNotifier.new,
);
```

`answer(index)` ignores repeated answers. `next()` refuses to advance before an answer. `complete()` writes exactly once and invalidates recent attempts after success. If saving throws, it returns an in-memory attempt with empty `id`/`userId` and `isSaved: false`, preserving the calculated score. `retrySave()` retries the same score payload and is also guarded against duplicate taps.

- [ ] **Step 5: Run provider tests**

Run: `flutter test test/presentation/provider/reviewer/question_bank_practice_provider_test.dart`

Expected: PASS for profile filtering, answer lock, score tracking, navigation state, and single-submit behavior.

- [ ] **Step 6: Inspect without committing**

Run: `git diff --check && git status --short`

---

### Task 5: Build subject/topic selection and repair routing

**Files:**
- Create: `lib/presentation/screens/question_bank/question_bank_subjects_screen.dart`
- Create: `lib/presentation/screens/question_bank/question_bank_topics_screen.dart`
- Create: `lib/presentation/widgets/question_bank/question_bank_status_view.dart`
- Modify: `lib/core/constants/routers/route_constants.dart`
- Modify: `lib/core/constants/routers/app_router.dart`
- Modify: `lib/core/utils/helpers.dart`
- Test: `test/presentation/screens/question_bank/question_bank_selection_test.dart`

**Interfaces:**
- Consumes: Task 2 route args and Task 4 async providers.
- Produces: `/question-bank/subjects` and `/question-bank/topics` destinations; the existing Question Bank card opens the former.

- [ ] **Step 1: Write failing navigation and selection widget tests**

```dart
testWidgets('Question Bank card opens its own subject screen', (tester) async {
  // Pump the category content with a test GoRouter containing both destinations.
  await tester.tap(find.text('Question Bank'));
  await tester.pumpAndSettle();
  expect(find.byType(QuestionBankSubjectsScreen), findsOneWidget);
  expect(find.byType(OnboardingMockboardScreen), findsNothing);
});

testWidgets('subject selection shows only provider subjects', (tester) async {
  // Override questionBankSubjectsProvider with Clinical Chemistry only.
  expect(find.text('Clinical Chemistry'), findsOneWidget);
  expect(find.text('Choose a subject from your registered course.'), findsOneWidget);
});
```

Also cover missing course, empty subjects, retryable errors, topic empty state, and tapping a topic.

- [ ] **Step 2: Run the selection tests and confirm missing screens/routes**

Run: `flutter test test/presentation/screens/question_bank/question_bank_selection_test.dart`

Expected: FAIL because the dedicated destinations do not exist and the current callback still uses `onboardingQuestions`.

- [ ] **Step 3: Add route constants and guarded route builders**

```dart
static const String questionBankSubjects = '/question-bank/subjects';
static const String questionBankTopics = '/question-bank/topics';
static const String questionBankPractice = '/question-bank/practice';
static const String questionBankResults = '/question-bank/results';
```

Each builder checks `state.extra` with `is QuestionBankTopicArgs`, `is QuestionBankPracticeArgs`, or `is QuestionBankResultArgs`; invalid extras render a small scaffold with `Content unavailable` and a button back to `questionBankSubjects`.

- [ ] **Step 4: Replace only the static Question Bank callback**

```dart
callback: (context) => context.push(RouteConstants.questionBankSubjects),
```

Do not change the `Mock Boards` label branch in `GridBadges` or the Pre Boards callback.

- [ ] **Step 5: Build selection screens from reusable components**

Use `CustomAppBar`, `ReviewerCategoryCard`, `RefreshIndicator`, and `QuestionBankStatusView`. The central navigation callbacks are:

```dart
ReviewerCategoryCard(
  icon: Icons.science_outlined,
  title: subject.title,
  subtitle: subject.description.isEmpty ? 'Practice this subject' : subject.description,
  onTap: () => context.push(
    RouteConstants.questionBankTopics,
    extra: QuestionBankTopicArgs(subject),
  ),
);

ReviewerCategoryCard(
  icon: Icons.quiz_outlined,
  title: topic.title,
  subtitle: 'Practice up to 20 questions',
  onTap: () => context.push(
    RouteConstants.questionBankPractice,
    extra: QuestionBankPracticeArgs(
      QuestionBankSelection(subject: subject, topic: topic),
    ),
  ),
);
```

`QuestionBankSubjectsScreen` watches both `questionBankSubjectsProvider` and `recentQuestionBankAttemptsProvider`. It lists subjects first, then renders at most five recent attempts as `Card > ListTile` rows with subject/topic, `correct / total`, percentage, and formatted completion date. `QuestionBankTopicsScreen` watches `questionBankTopicsProvider(subject.id)`. Both use `QuestionBankStatusView(message:, icon:, actionLabel:, onAction:)` for missing-course, empty, and error cases.

- [ ] **Step 6: Run selection and existing reviewer tests**

Run: `flutter test test/presentation/screens/question_bank/question_bank_selection_test.dart test/presentation/widgets/cards/questions_content_test.dart`

Expected: PASS.

- [ ] **Step 7: Inspect without committing**

Run: `git diff --check && git status --short`

---

### Task 6: Build the untimed practice and result experience

**Files:**
- Create: `lib/presentation/screens/question_bank/question_bank_practice_screen.dart`
- Create: `lib/presentation/screens/question_bank/question_bank_result_screen.dart`
- Test: `test/presentation/screens/question_bank/question_bank_practice_test.dart`
- Test: `test/presentation/screens/question_bank/question_bank_result_test.dart`

**Interfaces:**
- Consumes: `QuestionBankPracticeArgs`, `questionBankQuestionsProvider`, `questionBankSessionProvider`, `QuestionsContent`, and `ReusableButton`.
- Produces: answer-locking practice UI, completion save, result UI, save retry, repeat topic, and return-to-subjects actions.

- [ ] **Step 1: Write failing practice widget tests**

```dart
testWidgets('practice requires an answer and shows immediate feedback', (tester) async {
  // Override the questions provider with two known questions and pump the screen.
  expect(find.text('1 / 2'), findsOneWidget);
  expect(tester.widget<ElevatedButton>(find.text('NEXT').first).onPressed, isNull);
  await tester.tap(find.text('Wrong answer'));
  await tester.pump();
  expect(find.byKey(const ValueKey('choice-feedback-0')), findsOneWidget);
  expect(find.text('NEXT'), findsOneWidget);
});

testWidgets('last answered question completes once and opens results', (tester) async {
  // Answer the last question, tap VIEW RESULTS twice rapidly, and assert one fake save.
  expect(fakeRepository.saveCount, 1);
  expect(find.byType(QuestionBankResultScreen), findsOneWidget);
});
```

Cover progress updates, answer lock, fewer-than-20 sessions, no usable questions, save error visibility, and quit confirmation.

- [ ] **Step 2: Run tests and confirm screens are missing**

Run: `flutter test test/presentation/screens/question_bank/question_bank_practice_test.dart test/presentation/screens/question_bank/question_bank_result_test.dart`

Expected: FAIL on missing screens.

- [ ] **Step 3: Implement the practice screen**

On successful question load, initialize the session once. The active content is wired as follows:

```dart
final state = ref.watch(questionBankSessionProvider);
final notifier = ref.read(questionBankSessionProvider.notifier);
final question = state.questions[state.currentIndex];
final selectedIndex = state.selectedAnswers[question.id];

QuestionsContent(
  questionText: '${state.currentIndex + 1}. ${question.questionText}',
  choices: question.choices,
  selectedIndex: selectedIndex,
  onSelect: (index) {
    if (index != null) notifier.answer(index);
  },
);

ReusableButton(
  title: state.currentIndex == state.questions.length - 1
      ? 'VIEW RESULTS'
      : 'NEXT',
  onPressed: selectedIndex == null || state.isSubmitting
      ? null
      : () => _advanceOrComplete(context, ref),
  width: 280,
  height: 50,
);
```

Render `CustomAppBar`, `LinearProgressIndicator`, and the snippet above. Wrap back navigation in a confirmation dialog and do not import or start `timerProvider`.

- [ ] **Step 4: Implement completion and the result screen**

Await `session.complete()` and replace the route with a `QuestionBankResultArgs` built from its `QuestionBankCompletion`:

```dart
final completion = await ref
    .read(questionBankSessionProvider.notifier)
    .complete();
if (!context.mounted) return;
context.pushReplacement(
  RouteConstants.questionBankResults,
  extra: QuestionBankResultArgs(
    selection: selection,
    attempt: completion.attempt,
    isSaved: completion.isSaved,
  ),
);
```

When `isSaved` is false, the result screen shows `Result not saved` and its retry button calls `retrySave()` with the same selection and score. `PRACTICE AGAIN` invalidates `questionBankQuestionsProvider(selection.topic.id)` and replaces the route with `QuestionBankPracticeArgs(selection)`. `BACK TO SUBJECTS` calls `context.go(RouteConstants.questionBankSubjects)`.

- [ ] **Step 5: Run practice/result tests**

Run: `flutter test test/presentation/screens/question_bank/question_bank_practice_test.dart test/presentation/screens/question_bank/question_bank_result_test.dart`

Expected: PASS.

- [ ] **Step 6: Run all focused Question Bank tests**

Run: `flutter test test/core/utils/question_bank_helpers_test.dart test/data/repository/question_bank_repository_impl_test.dart test/presentation/provider/reviewer/question_bank_practice_provider_test.dart test/presentation/screens/question_bank test/supabase/question_bank_attempts_migration_test.dart`

Expected: PASS.

- [ ] **Step 7: Inspect without committing**

Run: `git diff --check && git status --short`

---

### Task 7: Regression verification and Graphify refresh

**Files:**
- Modify only if verification finds an issue: files already listed in Tasks 1-6.
- Update generated graph output through Graphify after source/tests are final.

**Interfaces:**
- Consumes: the complete implementation.
- Produces: formatted, analyzed, regression-tested source and a refreshed project knowledge graph.

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib test`

Expected: formatter exits successfully.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: no new errors or warnings caused by this feature.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`

Expected: all tests pass. If an unrelated pre-existing failure appears, record the exact test and prove focused Question Bank tests still pass.

- [ ] **Step 4: Verify no accidental Mock Boards coupling**

Run: `rg -n "timerProvider|quiz_attempts|replaceGeneratedMockboardCache|onboardingQuestions" lib/presentation/screens/question_bank lib/presentation/provider/reviewer/question_bank_practice_provider.dart lib/data/data_source/reviewer/question_bank_remote_datasource.dart`

Expected: no matches except none; the new flow is independent.

- [ ] **Step 5: Refresh Graphify**

Run from the workspace root: `graphify update`

Expected: `graphify-out/graph.json` includes the new Question Bank screens, providers, repository, datasource, tests, and migration.

- [ ] **Step 6: Final uncommitted diff review**

Run: `git diff --check`

Run: `git status --short`

Expected: only intended uncommitted feature/spec/plan/Graphify changes; no commit or push is performed.
