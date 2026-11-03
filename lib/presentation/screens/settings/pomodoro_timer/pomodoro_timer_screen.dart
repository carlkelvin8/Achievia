import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/cards/info_card.dart';
import 'package:achievia/presentation/widgets/settings/pomodoro_timer_controls_section.dart';
import 'package:achievia/presentation/widgets/settings/pomodoro_customize_section.dart';

class PomodoroTimerScreen extends ConsumerWidget {
  const PomodoroTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer'), centerTitle: true),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              InfoCard(
                icon: Icons.timer,
                title: 'Pomodoro Timer',
                description:
                    'Pomodoro Timer is a time-management tool that helps break your study into focused sessions with short breaks in between.',
              ),
              SizedBox(height: 16),

              // Timer Controls Section
              PomodoroTimerControlsSection(),
              SizedBox(height: 16),

              // Customize Section
              PomodoroCustomizeSection(),
            ],
          ),
        ),
      ),
    );
  }
}
