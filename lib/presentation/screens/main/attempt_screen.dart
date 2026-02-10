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
    print('attemptscreen:$attemptId');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attempt Results'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 12),
        child: AttemptCard(attemptId: int.tryParse('$attemptId') ?? 0,),
      ),
    );
  }
}