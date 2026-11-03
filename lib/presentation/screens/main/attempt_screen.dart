import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/cards/attempt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AttemptScreen extends ConsumerStatefulWidget {
  final int? attemptId;

  const AttemptScreen({super.key, this.attemptId});

  @override
  ConsumerState<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends ConsumerState<AttemptScreen> {
  @override
  Widget build(BuildContext context) {
    final attemptId = ref.watch(attemptIdProvider);
    final resolvedAttemptId = widget.attemptId ?? attemptId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Opened from Profile: back there. Right after an exam: home.
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteConstants.main);
            }
          },
        ),
        title: const Text('Attempt Results'),
      ),
      // Equal side padding; scrolls when the results are taller than the
      // screen instead of reserving empty space inside the card.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: AttemptCard(attemptId: resolvedAttemptId ?? 0),
        ),
      ),
    );
  }
}
