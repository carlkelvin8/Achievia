// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/pre_board_access.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/data/data_source/home/pre_board_remote_datasource.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_provider.dart';
import 'package:achievia/presentation/widgets/cards/questions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GridBadges extends ConsumerWidget {
  const GridBadges({super.key});

  /// Pre Boards open two weeks before the board exam and can be taken once.
  /// The server decides; the board itself is generated like a Mock Board.
  Future<void> _openPreBoards(
    BuildContext context,
    WidgetRef ref,
    QuestionsProvider provider,
    int index,
  ) async {
    // An unfinished Pre Board is continued (its one take is already used).
    if (await ref.read(mockBoardResumeProvider).tryRestore(isPreBoard: true)) {
      if (context.mounted) context.push(RouteConstants.preBoardOnboarding);
      return;
    }
    try {
      final status = await ref.read(preBoardRemoteProvider).status();
      if (!context.mounted) return;
      if (status.access != PreBoardAccess.available) {
        AppToast.showInfo(context, status.lockedMessage);
        return;
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.showError(context, preBoardErrorMessage(error));
      }
      return;
    }

    if (!context.mounted) return;
    final prepared = await provider.randomizeQuestion(
      index,
      context,
      isPreBoard: true,
    );
    if (!prepared || !context.mounted) return;
    context.push(RouteConstants.preBoardOnboarding);
  }

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
            iconAsset: item.iconAsset,
            label: item.label,
            subLabel: item.subLabel,
            callback: item.label == 'Mock Boards'
                ? (context) async {
                    // An unfinished exam is continued, never regenerated.
                    final resumed = await ref
                        .read(mockBoardResumeProvider)
                        .tryRestore(isPreBoard: false);
                    if (!context.mounted) return;
                    if (resumed) {
                      context.push(RouteConstants.onboardingQuestions);
                      return;
                    }
                    final prepared = await provider.randomizeQuestion(
                      index,
                      context,
                    );
                    if (!prepared || !context.mounted) return;
                    context.push(RouteConstants.onboardingQuestions);
                  }
                : item.label == 'Pre Boards'
                ? (context) => _openPreBoards(context, ref, provider, index)
                : item.callback,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemCount: questionItems.length,
      ),
    );
  }
}
