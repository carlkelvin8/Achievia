import 'package:achievia/core/constants/philippine_schools.dart';
import 'package:flutter/material.dart';

/// The sign-up "University / School" field. It looks like the other fields
/// but opens a picker: a searchable list of schools, plus a "School not
/// listed?" box for typing a school that is not in the list.
///
/// The chosen school is written to [controller], so the rest of the sign-up
/// flow keeps reading it exactly as before.
class SchoolPickerField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const SchoolPickerField({
    super.key,
    required this.controller,
    this.validator,
  });

  Future<void> _open(BuildContext context) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => SchoolPickerDialog(initial: controller.text),
    );
    if (picked != null && picked.trim().isNotEmpty) {
      controller.text = picked.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const ValueKey('school-field'),
      controller: controller,
      readOnly: true,
      validator: validator,
      onTap: () => _open(context),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        hintText: 'University / School',
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFDBDEE4)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(0)),
          borderSide: BorderSide(color: Colors.black),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 248, 17, 0)),
        ),
      ),
    );
  }
}

class SchoolPickerDialog extends StatefulWidget {
  final String initial;

  const SchoolPickerDialog({super.key, this.initial = ''});

  @override
  State<SchoolPickerDialog> createState() => _SchoolPickerDialogState();
}

class _SchoolPickerDialogState extends State<SchoolPickerDialog> {
  final _search = TextEditingController();
  final _custom = TextEditingController();
  String _query = '';
  String? _selected;

  @override
  void initState() {
    super.initState();
    if (philippineSchools.contains(widget.initial)) {
      _selected = widget.initial;
    } else {
      _custom.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    super.dispose();
  }

  void _use(String school) => Navigator.of(context).pop(school);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = [
      for (final s in philippineSchools)
        if (schoolMatches(s, _query)) s,
    ];
    final custom = _custom.text.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'University / School',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              TextField(
                key: const ValueKey('school-search'),
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search your school...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          key: const ValueKey('school-empty'),
                          child: Text(
                            'No matching school. Enter it below.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : RadioGroup<String>(
                        groupValue: _selected,
                        onChanged: (value) {
                          if (value != null) _use(value);
                        },
                        child: ListView.builder(
                          key: const ValueKey('school-list'),
                          shrinkWrap: true,
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final school = matches[index];
                            return RadioListTile<String>(
                              key: ValueKey('school-$school'),
                              value: school,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.trailing,
                              title: Text(
                                school,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const Divider(height: 20),
              Text(
                'School not listed?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enter your university or school below.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('school-custom'),
                controller: _custom,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter school name',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('school-use'),
                  onPressed: custom.isEmpty ? null : () => _use(custom),
                  child: const Text('Use this school'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
