import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/examination/examination_info_card.dart';
import 'package:achievia/presentation/widgets/examination/examination_config_card.dart';
import 'package:achievia/presentation/provider/examination/examination_provider.dart';
import 'package:achievia/domain/entities/widgets/examination_config_entity.dart';
import 'package:achievia/presentation/widgets/dialogs/radio_selection_dialog.dart';

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
  ) async {
    final selected = await RadioSelectionDialog.show<int>(
      context: context,
      title: 'Select Number of Items',
      options: ExaminationConfig.itemOptions,
      selectedValue: config.numberOfItems,
      optionLabel: (items) => '$items items',
    );
    
    if (selected != null) {
      notifier.updateNumberOfItems(selected);
    }
  }

  void _showDurationDialog(
    BuildContext context,
    ExaminationConfig config,
    ExaminationConfigNotifier notifier,
  ) async {
    final selected = await RadioSelectionDialog.show<int>(
      context: context,
      title: 'Select Duration',
      options: ExaminationConfig.durationOptions,
      selectedValue: config.durationMinutes,
      optionLabel: (minutes) {
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        if (hours > 0) {
          return remainingMinutes > 0
              ? '${hours}h $remainingMinutes m'
              : '${hours}h';
        }
        return '$minutes mins';
      },
    );
    
    if (selected != null) {
      notifier.updateDuration(selected);
    }
  }
}
