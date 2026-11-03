import 'dart:async';
import 'dart:io';
import 'package:achievia/domain/entities/api/task/task_api_entity.dart';
import 'package:achievia/domain/entities/api/task/task_entity.dart';
import 'package:achievia/domain/entities/widgets/goal_entity.dart';
import 'package:achievia/domain/use_cases/task/task_use_case.dart';
import 'package:achievia/presentation/provider/auth/event/token_state_provider.dart';
import 'package:achievia/presentation/provider/home/home_provider.dart';
import 'package:achievia/presentation/provider/task/local_day_provider.dart';
import 'package:achievia/presentation/provider/task/task_provider.dart';
import 'package:achievia/presentation/widgets/home/today_goal_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

TaskApiEntity task(String name, DateTime deadline, {bool done = false}) =>
    TaskApiEntity(
      id: name,
      taskName: name,
      description: 'Study Nematodes',
      userId: 'user',
      isDone: done,
      deadline: deadline,
      createdAt: DateTime(2026, 9, 1),
    );

class FakeTasks implements TaskUseCase {
  List<TaskApiEntity> items = [];
  @override
  Future<List<TaskApiEntity>> getTasks() async => List.of(items);
  @override
  Future<void> createTask(TaskEntity entity) async {
    items.add(task(entity.tasksName, entity.deadline));
  }

  @override
  Future<void> markTaskDone(String id) async {
    items = items
        .map(
          (item) => item.id == id
              ? task(item.taskName, item.deadline, done: true)
              : item,
        )
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FailingTasks extends FakeTasks {
  FailingTasks(this.error);
  final Object error;
  bool failing = true;
  @override
  Future<List<TaskApiEntity>> getTasks() async {
    if (failing) throw error;
    return super.getTasks();
  }
}

class FakeGoal extends GoalNotifier {
  final Future<GoalEntity?> result;
  FakeGoal(this.result);
  @override
  Future<GoalEntity?> build() => result;
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeTasks tasks, {
    Future<GoalEntity?>? goal,
    DateTime Function()? clock,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStream.overrideWith((ref) => Stream.value('signed-in')),
          taskUseCaseProvider.overrideWithValue(tasks),
          taskClockProvider.overrideWithValue(
            clock ?? () => DateTime(2026, 9, 25, 12),
          ),
          goalProvider.overrideWith(() => FakeGoal(goal ?? Future.value(null))),
        ],
        child: const MaterialApp(home: Scaffold(body: TodayGoalSection())),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(TodayGoalSection)),
    );
  }

  testWidgets(
    'shows only unfinished reminders on the local date, with an existing goal',
    (tester) async {
      final tasks = FakeTasks()
        ..items = [
          task('Parasitology', DateTime(2026, 9, 25, 0).toUtc()),
          task('Tonight', DateTime(2026, 9, 25, 23, 59).toUtc()),
          task('Yesterday', DateTime(2026, 9, 24)),
          task('Tomorrow', DateTime(2026, 9, 26)),
          task('Completed', DateTime(2026, 9, 25), done: true),
        ];
      await pump(
        tester,
        tasks,
        goal: Future.value(
          GoalEntity(
            id: 'goal',
            date: DateTime(2026, 9, 25),
            title: 'Separate goal',
            details: 'Review',
          ),
        ),
      );
      expect(find.text('Parasitology'), findsOneWidget);
      expect(find.text('Tonight'), findsOneWidget);
      expect(find.text('Separate goal'), findsOneWidget);
      expect(find.text('Yesterday'), findsNothing);
      expect(find.text('Tomorrow'), findsNothing);
      expect(find.text('Completed'), findsNothing);
      expect(find.text('No goal set for today'), findsNothing);
    },
  );

  testWidgets('saving and completing a reminder updates Home immediately', (
    tester,
  ) async {
    final tasks = FakeTasks();
    final container = await pump(tester, tasks);
    expect(find.text('No goal set for today'), findsOneWidget);
    await container
        .read(createTaskProvider.notifier)
        .createTask(
          TaskEntity(
            tasksName: 'Parasitology',
            description: 'Study Nematodes',
            deadline: DateTime(2026, 9, 25),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Parasitology'), findsOneWidget);
    await tester.tap(find.text('Parasitology'));
    await tester.pumpAndSettle();
    expect(find.text('Parasitology'), findsNothing);
    expect(tasks.items.single.isDone, isTrue);
  });

  testWidgets('pending dedicated goal cannot block today reminders', (
    tester,
  ) async {
    final pending = Completer<GoalEntity?>();
    final tasks = FakeTasks()
      ..items = [task('Parasitology', DateTime(2026, 9, 25))];
    await pump(tester, tasks, goal: pending.future);
    expect(find.text('Parasitology'), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('today reminders roll over at midnight while Home stays open', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 25, 23, 59, 59);
    final tasks = FakeTasks()
      ..items = [
        task('Today', DateTime(2026, 9, 25)),
        task('Next day', DateTime(2026, 9, 26)),
      ];
    await pump(tester, tasks, clock: () => now);
    expect(find.text('Today'), findsOneWidget);
    now = DateTime(2026, 9, 26);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Next day'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('a network failure shows the safe connection message', (
    tester,
  ) async {
    final tasks = FailingTasks(
      const SocketException(
        "Failed host lookup: 'bcxvjfxrdfzqzmoseegx.supabase.co'",
      ),
    );
    await pump(tester, tasks);

    expect(
      find.textContaining('Unable to connect to the server'),
      findsOneWidget,
    );
    expect(find.textContaining('supabase'), findsNothing);
    expect(find.textContaining('SocketException'), findsNothing);
  });

  testWidgets('another failure shows no raw backend text', (tester) async {
    final tasks = FailingTasks(
      StateError('PostgrestException(code: 42501, message: permission denied)'),
    );
    await pump(tester, tasks);

    expect(find.text('Unable to load reminders. Retry'), findsOneWidget);
    expect(find.textContaining('Postgrest'), findsNothing);
    expect(find.textContaining('permission denied'), findsNothing);
  });

  testWidgets('Retry recovers once the request works again', (tester) async {
    final tasks = FailingTasks(const SocketException('Failed host lookup'))
      ..items = [task('Parasitology', DateTime(2026, 9, 25, 9))];
    await pump(tester, tasks);
    expect(find.textContaining('Retry'), findsOneWidget);

    tasks.failing = false;
    await tester.tap(find.textContaining('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Parasitology'), findsOneWidget);
    expect(find.textContaining('Retry'), findsNothing);
  });

  testWidgets('no reminders is a normal empty state, not an error', (
    tester,
  ) async {
    await pump(tester, FakeTasks());

    expect(find.text('No goal set for today'), findsOneWidget);
    expect(find.textContaining('Unable'), findsNothing);
    expect(find.textContaining('Retry'), findsNothing);
  });
}
