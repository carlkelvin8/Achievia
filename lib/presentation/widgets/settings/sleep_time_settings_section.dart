import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';

/// Sleep time settings section with time picker
class SleepTimeSettingsSection extends ConsumerWidget {
  const SleepTimeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepTime = ref.watch(sleepTimeProvider);

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsItem(
            icon: Icons.bedtime_outlined,
            title: 'Sleep time',
            trailing: _buildSleepTimeButton(context, ref, sleepTime),
          ),
          const SettingsDescription(
            'While Achievia is open, Sleep Time shows a reminder on screen at your chosen time to help you rest, promoting healthier study habits and balanced screen time. Reminders do not appear when the app is closed or in the background.',
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimeButton(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay sleepTime,
  ) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: sleepTime,
        );
        if (picked != null) {
          await ref.read(sleepTimeProvider.notifier).save(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          sleepTime.format(context),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
