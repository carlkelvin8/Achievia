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
          const SizedBox(height: 8),
          Text(
            'Sleep Time automatically sends notifications and reminds you to rest, promoting healthier study habits and balanced screen time.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
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
          ref.read(sleepTimeProvider.notifier).state = picked;
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
