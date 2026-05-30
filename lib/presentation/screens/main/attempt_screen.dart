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
          onPressed: () {
            context.go(RouteConstants.main);
          },
        ),
        title: const Text('Attempt Results'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 12),
        child: AttemptCard(attemptId: resolvedAttemptId ?? 0),
      ),
    );
  }
}
