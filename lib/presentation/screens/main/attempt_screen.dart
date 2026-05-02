import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/cards/attempt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttemptScreen extends ConsumerStatefulWidget {
  const AttemptScreen({super.key});

  @override
  ConsumerState<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends ConsumerState<AttemptScreen> {
  @override
  Widget build(BuildContext context) {
    final attemptId = ref.watch(attemptIdProvider);
    final routeAttemptId = ModalRoute.of(context)?.settings.arguments as int?;
    final resolvedAttemptId = routeAttemptId ?? attemptId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
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
