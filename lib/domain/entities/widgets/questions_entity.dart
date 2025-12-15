// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class QuestionsEntityWidget {
  final IconData icon;
  final String label;
  final String sub_label;
  final void Function(BuildContext context)? callback;
  QuestionsEntityWidget({
    required this.icon,
    required this.label,
    required this.sub_label,
    this.callback
  });
}
