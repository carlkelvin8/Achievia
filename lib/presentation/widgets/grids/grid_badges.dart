// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/cards/questions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GridBadges extends ConsumerWidget {
  final String token;
  final String id;
  final String title;
  const GridBadges({
    super.key,
    required this.token,
    required this.id,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(answerQotProvider.notifier);
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) {
          final item = questions[index];

          return QuestionsCard(
            icon: item.icon,
            label: item.label,
            sub_label: item.sub_label,
            callback: item.label == 'Mock Boards'
                ? (context) async {
                    await provider.randomizeQuestion(index, context);
                    if (!context.mounted) return;
                    context.push(RouteConstants.onboardingQuestions);
                  }
                : item.callback,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: questions.length,
      ),
    );
  }
}
