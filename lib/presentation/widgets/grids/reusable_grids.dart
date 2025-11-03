// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/cards/notes_card.dart';

class ReusableGrids extends ConsumerWidget {
  final int crossAxisCount;
  final int itemCount;
  final int itemCount2;
  final String text;
  final String today;
  final String yesterday;
  final IconData icon;

  const ReusableGrids({
    super.key,
    required this.crossAxisCount,
    required this.itemCount,
    required this.itemCount2,
    required this.text,
    required this.today,
    required this.yesterday,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final reminder = notes[index];
                return NotesCard(
                  image: reminder.image,
                  title: reminder.title,
                );
              },
            ),

            const SizedBox(height: 20),

            // 🟨 YESTERDAY SECTION
            Text(
              yesterday,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: itemCount2,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final reminder = notes2[index];
                return NotesCard(
                  image: reminder.image,
                  title: reminder.title,
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(),

            _buildReminder(context, text, icon),
          ],
        ),
      ),
    );
  }
}

// 🔹 Reusable footer row
Widget _buildReminder(BuildContext context, String text, IconData icon) {
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      Icon(icon, color: colorScheme.primary),
    ],
  );
}
