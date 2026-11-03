import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Settings entry that opens the Answer Feedback screen.
class AnswerFeedbackSettingsSection extends StatelessWidget {
  const AnswerFeedbackSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      onTap: () => context.push(RouteConstants.answerFeedback),
      child: const SettingsItem(
        icon: Icons.volume_up_outlined,
        title: 'Answer Feedback',
        subtitle: 'Answer sounds and vibration',
        trailing: Icon(Icons.arrow_forward_ios, color: headerColor2, size: 16),
      ),
    );
  }
}
