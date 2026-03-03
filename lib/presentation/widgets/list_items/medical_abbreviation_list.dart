import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:flutter/material.dart';

class MedicalAbbreviationsList extends StatelessWidget {
  const MedicalAbbreviationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        itemCount: medicalAbbreviations.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey,
        ),
        itemBuilder: (context, index) {
          final abbrev = medicalAbbreviations[index];
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
            onTap: () {
              // Optional: Handle tap, e.g., show details or copy
              SnackBarUtils.showInfo(context, 'Tapped: ${abbrev.abbreviation}');
            },
          );
        },
      );
  }
}