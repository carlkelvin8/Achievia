# Question Bank Practice Design

## Goal

Give the Question Bank card its own course-filtered practice flow instead of sending users into Mock Boards. A signed-in user chooses a subject and topic, answers up to 20 randomized questions without a timer, receives immediate answer feedback, sees a final score, and has the completed attempt saved in Supabase.

## Scope

This feature changes only the Question Bank card and adds the supporting Question Bank flow. Mock Boards, Pre Boards, their timer, generated mock-board cache, scoring rules, and attempt submission remain unchanged.

## User Flow

1. The existing `/reviewers/question-bank` page continues to show Question Bank, Mock Boards, and Pre Boards.
2. Tapping the Question Bank card opens a dedicated subject-selection screen.
3. The screen reads the signed-in user's `profiles.course_id` and lists only `subjects` whose `course_id` matches it.
4. Selecting a subject opens its topics, sourced from `quizzes.subject_id`.
5. Selecting a topic starts a practice session made from up to 20 randomized rows from `questions.quiz_id`, with matching rows from `choices.question_id`.
6. Each question uses the reusable `QuestionsContent` widget. Selecting an answer immediately shows correct/incorrect feedback and locks that answer.
7. The user advances with reusable buttons. There is no timer, unanswered-question drawer, mock-board section switching, or board-exam pass/fail calculation.
8. On the last question, the app calculates `correct / total * 100`, saves the attempt, and opens a dedicated result screen.
9. The subject-selection screen shows the five most recent saved attempts so the user can see recent progress.

If a topic contains fewer than 20 questions, all available questions are used. A topic with no usable questions or no choices cannot start and shows a clear empty-state message.

## Architecture

The feature follows the existing Flutter layers while staying isolated from Mock Boards:

- A Question Bank remote data source owns Supabase queries and attempt inserts.
- A Question Bank repository exposes domain-level subjects, topics, practice questions, and attempts.
- Riverpod providers combine the existing `profileProvider` course ID with the Question Bank repository and hold the active session state.
- Dedicated screens render subjects, topics, the active practice session, results, and recent attempts.
- Existing shared presentation widgets are reused where their behavior fits; mock-board-specific providers and caching are not reused.

The new Question Bank repository is created by a Riverpod provider rather than adding generated dependency-injection output. This keeps the feature testable through provider overrides and avoids requiring ignored generated DI files.

## Domain Types

Add focused immutable types instead of overloading mock-board entities:

- `QuestionBankSubject`: `id`, `title`, `description`, `courseId`, optional `image`.
- `QuestionBankTopic`: `id`, `subjectId`, `title`, `description`.
- `QuestionBankSelection`: selected subject and topic passed into the practice route.
- `QuestionBankAttempt`: `id`, `userId`, `subjectId`, `topicId`, subject/topic labels, `correctAnswers`, `totalQuestions`, `score`, and `completedAt`.

Practice questions reuse `QuestionItemEntity` and `ChoiceEntity`, because those types already match `questions` and `choices` and are consumed by `QuestionsContent`.

## Supabase Queries

All queries run as the authenticated user:

- Profile: existing `profileProvider` supplies `courseId`.
- Subjects: `subjects.select(...).eq('course_id', courseId).order('title')`.
- Topics: `quizzes.select(...).eq('subject_id', subjectId).order('title')`.
- Questions: load question IDs/text for the selected quiz.
- Choices: load choices for those candidate question IDs, group by `question_id`, discard questions with no choices, shuffle the usable questions in Dart, and retain at most 20.
- Recent attempts: load the signed-in user's latest five `question_bank_attempts` rows ordered by `completed_at desc`.

The question selection helper accepts a `Random` instance so randomization and the 20-question limit can be tested deterministically.

## Database Migration

Create `public.question_bank_attempts` with:

- `id uuid primary key default gen_random_uuid()`
- `user_id uuid not null references public.profiles(id) on delete cascade`
- `subject_id integer not null references public.subjects(id) on delete cascade`
- `quiz_id integer not null references public.quizzes(id) on delete cascade`
- `correct_answers integer not null check (correct_answers >= 0)`
- `total_questions integer not null check (total_questions > 0)`
- `score numeric(5,2) not null check (score between 0 and 100)`
- `completed_at timestamptz not null default now()`

Add indexes on `(user_id, completed_at desc)` and `(user_id, quiz_id)`. Enable RLS with policies that allow authenticated users to select and insert only rows whose `user_id = auth.uid()`. No update or delete policy is needed for this feature.

Subject and topic labels are resolved from the related in-memory selection for the result screen. The attempt table stores stable IDs and numeric results rather than duplicating labels.

## Screens and Reusable Widgets

### Existing category page

Change only the Question Bank item's callback in `helpers.dart` to push the new subject route. Mock Boards retains its current generation/onboarding callback, and Pre Boards retains its existing behavior.

### Subject selection

- `CustomAppBar` with title `Question Bank`.
- Introductory text explaining that subjects match the user's registered course.
- Subject cards use the visual language of `ReviewerCategoryCard`/`QuestionsCard` rather than introducing a new card system.
- A compact `Recent Practice` section shows the five latest attempts.
- Loading, retry, missing-course, and no-subject states are rendered in the body.

### Topic selection

- `CustomAppBar` titled with the selected subject.
- Topic cards show the topic title and a `20 questions` or `N questions available` description when count information is available.
- Empty and retry states remain on this screen.

### Practice session

- `CustomAppBar` shows the topic name and `current / total` progress.
- A linear progress indicator sits beneath the app bar.
- `QuestionsContent` renders the question and choices with immediate feedback.
- `ReusableButton` advances to the next question and changes to `VIEW RESULTS` on the last question.
- The advance action is disabled until the current question has been answered.
- Back navigation asks for confirmation before abandoning an in-progress session.

### Results

- Shows correct answers, total questions, and percentage score.
- Confirms whether the result was saved.
- Offers `PRACTICE AGAIN` for the same topic and `BACK TO SUBJECTS`.

## State and Navigation

Add explicit route constants for subject selection, topic selection, practice, and results. Route builders validate `state.extra` before constructing screens and show a recoverable fallback when route arguments are missing.

Providers expose:

- Course-filtered subjects.
- Topics by subject ID.
- A randomized practice question list by topic ID.
- Recent attempts.
- An active, auto-disposed session notifier that tracks current index, selected answers, and correct count.

Completion writes one attempt, invalidates recent-attempt providers, and then displays results. Starting another session creates a new randomized set and reset state.

## Error Handling

- Missing or expired authentication: show a session-expired message and rely on the existing auth router for redirection.
- Missing `course_id`: explain that the profile needs a course assignment; do not show unrelated subjects.
- No matching subjects/topics/questions: show a specific empty state with back or retry action.
- Questions without choices: exclude them before the session starts.
- Network/query failures: show a retryable error without silently falling back to Mock Boards.
- Attempt-save failure: keep the calculated result visible, label it as not saved, and provide a retry action.
- A loading action cannot be submitted twice.

## Testing

- Unit-test randomized selection: maximum 20, fewer-than-20 behavior, deterministic input, and exclusion of questions without choices.
- Unit-test score calculation for zero, partial, and perfect results.
- Provider/repository tests use fakes to verify course filtering, topic loading, recent-attempt invalidation, and attempt payloads.
- Widget-test the existing Question Bank card to ensure it opens the new subject screen and does not open Mock Boards.
- Widget-test subject and topic loading/empty/error states.
- Widget-test practice behavior: answer lock, immediate feedback, disabled advance before answering, progress changes, and final result.
- Migration tests verify the table, constraints, indexes, and owner-only RLS policies.
- Run focused tests, the full Flutter test suite, static analysis, and formatting checks before completion.

## Acceptance Criteria

- Tapping the Question Bank card never opens the Mock Boards onboarding screen.
- A user sees only subjects for their profile's `course_id`.
- A user can choose a subject and topic and receive at most 20 randomized usable questions.
- Answers display immediate correct/incorrect feedback and cannot be changed.
- The session has no timer and does not write to `quiz_attempts` or mock-board caches.
- Completion shows a correct score and persists an owner-scoped `question_bank_attempts` row.
- The five most recent attempts appear on the subject-selection screen.
- Loading, missing-data, empty, and error states are understandable and retryable.
- Existing Mock Boards behavior and tests remain intact.
