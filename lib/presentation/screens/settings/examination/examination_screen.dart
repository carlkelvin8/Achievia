import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/widgets/examination/examination_info_card.dart';
import 'package:achievia/presentation/widgets/examination/examination_customize_section.dart';
import 'package:achievia/presentation/widgets/examination/examination_reset_section.dart';

class ExaminationScreen extends ConsumerWidget {
  const ExaminationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Examination Info Card
            ExaminationInfoCard(),
            SizedBox(height: 32),

            // Customize Section
            ExaminationCustomizeSection(),
            SizedBox(height: 32),

            // Reset Section
            ExaminationResetSection(),
          ],
        ),
      ),
    );
  }
}
