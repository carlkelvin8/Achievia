import 'package:achievia/core/utils/pomodoro_labels.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/settings/setting_tile.dart';
import 'package:achievia/presentation/widgets/settings/settings_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Customize section for pomodoro duration settings
class PomodoroCustomizeSection extends ConsumerWidget {
  const PomodoroCustomizeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(pomodoroSettingsProvider);
    final settingsNotifier = ref.read(pomodoroSettingsProvider.notifier);

    return SettingsGroupCard(
      title: 'Customize',
      children: [
        SettingTile(
          label: 'Review duration',
          valueLabel: formatMinutesLabel(settings.focusDuration.inMinutes),
          onTap: () => _editValue(
            context: context,
            title: 'Review duration (mins)',
            initial: settings.focusDuration.inMinutes,
            min: 1,
            max: 180,
            onSubmit: (v) => settingsNotifier.setFocusMinutes(v),
          ),
          onDecrement: () => settingsNotifier.setFocusMinutes(
            (settings.focusDuration.inMinutes - 5).clamp(5, 120),
          ),
          onIncrement: () => settingsNotifier.setFocusMinutes(
            (settings.focusDuration.inMinutes + 5).clamp(5, 120),
          ),
        ),
        SettingTile(
          label: 'Short break duration',
          valueLabel: formatMinutesLabel(settings.shortBreakDuration.inMinutes),
          onTap: () => _editValue(
            context: context,
            title: 'Short break (mins)',
            initial: settings.shortBreakDuration.inMinutes,
            min: 1,
            max: 60,
            onSubmit: (v) => settingsNotifier.setShortBreakMinutes(v),
          ),
          onDecrement: () => settingsNotifier.setShortBreakMinutes(
            (settings.shortBreakDuration.inMinutes - 1).clamp(1, 60),
          ),
          onIncrement: () => settingsNotifier.setShortBreakMinutes(
            (settings.shortBreakDuration.inMinutes + 1).clamp(1, 60),
          ),
        ),
        SettingTile(
          label: 'Long break duration',
          valueLabel: formatMinutesLabel(settings.longBreakDuration.inMinutes),
          onTap: () => _editValue(
            context: context,
            title: 'Long break (mins)',
            initial: settings.longBreakDuration.inMinutes,
            min: 5,
            max: 180,
            onSubmit: (v) => settingsNotifier.setLongBreakMinutes(v),
          ),
          onDecrement: () => settingsNotifier.setLongBreakMinutes(
            (settings.longBreakDuration.inMinutes - 5).clamp(5, 120),
          ),
          onIncrement: () => settingsNotifier.setLongBreakMinutes(
            (settings.longBreakDuration.inMinutes + 5).clamp(5, 120),
          ),
        ),
        SettingTile(
          label: 'Sessions before long break',
          // Wider than the default so "10 sessions" is not cut off.
          controlWidth: 180,
          valueLabel: formatSessionsLabel(settings.sessionsBeforeLongBreak),
          onTap: () => _editValue(
            context: context,
            title: 'Sessions before long break',
            initial: settings.sessionsBeforeLongBreak,
            min: 1,
            max: 10,
            onSubmit: (v) => settingsNotifier.setSessionsBeforeLong(v),
          ),
          onDecrement: () => settingsNotifier.setSessionsBeforeLong(
            (settings.sessionsBeforeLongBreak - 1).clamp(1, 10),
          ),
          onIncrement: () => settingsNotifier.setSessionsBeforeLong(
            (settings.sessionsBeforeLongBreak + 1).clamp(1, 10),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default'),
          value: settings.defaultEnabled,
          onChanged: (v) => settingsNotifier.toggleDefault(v),
        ),
      ],
    );
  }

  Future<void> _editValue({
    required BuildContext context,
    required String title,
    required int initial,
    required int min,
    required int max,
    required void Function(int) onSubmit,
  }) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) =>
          _NumberEditDialog(title: title, initial: initial, min: min, max: max),
    );
    if (value != null) {
      onSubmit(value);
    }
  }
}

/// Owns its text controller so it is disposed together with the dialog route,
/// after the close animation has finished.
class _NumberEditDialog extends StatefulWidget {
  const _NumberEditDialog({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final int initial;
  final int min;
  final int max;

  @override
  State<_NumberEditDialog> createState() => _NumberEditDialogState();
}

class _NumberEditDialogState extends State<_NumberEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(parsed.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(hintText: 'Enter a value'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
