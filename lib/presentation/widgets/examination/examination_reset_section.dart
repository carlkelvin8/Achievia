import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/examination/examination_config_card.dart';
import 'package:achievia/presentation/provider/examination/examination_provider.dart';

/// Reset section for examination configuration
/// Displays default toggle to reset settings
class ExaminationResetSection extends ConsumerWidget {
  const ExaminationResetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(examinationConfigProvider);
    final configNotifier = ref.read(examinationConfigProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Default Toggle
        ExaminationToggleCard(
          title: 'Default',
          value: config.isDefault,
          icon: Icons.restore,
          onChanged: (value) {
            if (value) {
              configNotifier.resetToDefault();
            } else {
              configNotifier.toggleDefault();
            }
          },
        ),
      ],
    );
  }
}
