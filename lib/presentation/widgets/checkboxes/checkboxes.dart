import 'package:achievia/core/constants/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class Checkboxes extends StatefulWidget {
  final bool? isChecked;
  final ValueChanged<bool?>? onChanged;
  const Checkboxes({super.key, required this.isChecked, this.onChanged});

  @override
  State<Checkboxes> createState() => _CheckboxesState();
}

class _CheckboxesState extends State<Checkboxes> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: headerColor3,
      title: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Keep me logged in",
              style: TextStyle(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      ),
      value: widget.isChecked ?? false,
      onChanged: widget.onChanged,
    );
  }
}
