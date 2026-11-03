import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final taskClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final localDayProvider =
    NotifierProvider.autoDispose<LocalDayNotifier, DateTime>(
      LocalDayNotifier.new,
    );

class LocalDayNotifier extends Notifier<DateTime> {
  Timer? _timer;
  DateTime _today() {
    final now = ref.read(taskClockProvider)().toLocal();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  DateTime build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _timer?.cancel();
      listener.dispose();
    });
    _schedule();
    return _today();
  }

  void refresh() {
    final today = _today();
    if (today != state) state = today;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = ref.read(taskClockProvider)().toLocal();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(nextDay.difference(now), refresh);
  }
}
