import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/examination/examination_info_card.dart';
import 'package:achievia/presentation/widgets/examination/examination_config_card.dart';
import 'package:achievia/presentation/provider/examination/examination_provider.dart';
import 'package:achievia/domain/entities/examination_config_entity.dart';

class ExaminationScreen extends ConsumerStatefulWidget {
  const ExaminationScreen({super.key});

  @override
  ConsumerState<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends ConsumerState<ExaminationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(examinationConfigProvider);
    final configNotifier = ref.read(examinationConfigProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Examination'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.close, color: theme.colorScheme.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Examination Info Card
            const ExaminationInfoCard(),
            const SizedBox(height: 32),

            // Customize Section
            Text(
              'Customize',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Number of Items Configuration
            ExaminationConfigCard(
              title: 'Number of items',
              value: configNotifier.getFormattedItems(),
              icon: Icons.format_list_numbered,
              onTap: () => _showItemsDialog(context, config, configNotifier),
            ),
            const SizedBox(height: 8),

            // Duration Configuration
            ExaminationConfigCard(
              title: 'Duration',
              value: configNotifier.getFormattedDuration(),
              icon: Icons.timer_outlined,
              onTap: () => _showDurationDialog(context, config, configNotifier),
            ),
            const SizedBox(height: 32),

            // Reset Section
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
        ),
      ),
    );
  }

  void _showItemsDialog(
    BuildContext context,
    ExaminationConfig config,
    ExaminationConfigNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Number of Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExaminationConfig.itemOptions.map((items) {
            return RadioListTile<int>(
              title: Text('$items items'),
              value: items,
              groupValue: config.numberOfItems,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateNumberOfItems(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDurationDialog(
    BuildContext context,
    ExaminationConfig config,
    ExaminationConfigNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExaminationConfig.durationOptions.map((minutes) {
            final hours = minutes ~/ 60;
            final remainingMinutes = minutes % 60;
            String durationText;
            if (hours > 0) {
              durationText = remainingMinutes > 0
                  ? '${hours}h $remainingMinutes m'
                  : '${hours}h';
            } else {
              durationText = '$minutes mins';
            }

            return RadioListTile<int>(
              title: Text(durationText),
              value: minutes,
              groupValue: config.durationMinutes,
              onChanged: (value) {
                if (value != null) {
                  notifier.updateDuration(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
