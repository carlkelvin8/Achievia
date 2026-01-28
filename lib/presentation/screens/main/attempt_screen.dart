import 'package:achievia/presentation/widgets/cards/attempt_card.dart';
import 'package:flutter/material.dart';

class AttemptScreen extends StatefulWidget {
  const AttemptScreen({super.key});

  @override
  State<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends State<AttemptScreen> {
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attempt Results'),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 12, horizontal: 12),
        child: AttemptCard(),
      ),
    );
  }
}