import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/presentation/provider/reviewer/supplementals_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicalAbbreviationsList extends ConsumerWidget {
  const MedicalAbbreviationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abbreviations =
        ref.watch(supplementalsProvider).value?.abbreviations ?? const [];
    return ListView.separated(
      itemCount: abbreviations.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final abbrev = abbreviations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              abbrev.abbreviation,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          title: Text(abbrev.abbreviation),
          subtitle: Text(abbrev.expansion),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () =>
              AppToast.showInfo(context, 'Tapped: ${abbrev.abbreviation}'),
        );
      },
    );
  }
}
