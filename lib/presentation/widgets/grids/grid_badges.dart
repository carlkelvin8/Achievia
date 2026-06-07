// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_provider.dart';
import 'package:achievia/presentation/widgets/cards/questions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GridBadges extends ConsumerWidget {
  const GridBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(answerQotProvider.notifier);
    final questionItems = ref.watch(questionBankItemsProvider);
    return Expanded(
      child: ListView.separated(
        itemBuilder: (context, index) {
          final item = questionItems[index];

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
        itemCount: questionItems.length,
      ),
    );
  }
}
