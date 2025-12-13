// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/cards/questions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

     return Expanded(child: ListView.separated(itemBuilder: (context, index) => QuestionsCard(
      icon: questions[index].icon, 
      label: questions[index].label, 
      sub_label: questions[index].sub_label), 
      separatorBuilder: (context, index) => const SizedBox(height: 10,), 
      itemCount: questions.length)
    );
}
}