// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class QuestionsEntityWidget {
  final IconData icon;
  final String? iconAsset;
  final String label;
  final String subLabel;
  final void Function(BuildContext context)? callback;
  QuestionsEntityWidget({
    required this.icon,
    this.iconAsset,
    required this.label,
    required this.subLabel,
    this.callback,
  });
}
