import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/theme/theme_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:achievia/presentation/widgets/buttons/theme_toggle_button.dart';

/// Theme settings section with dark/light mode toggle
class ThemeSettingsSection extends ConsumerWidget {
  const ThemeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SettingsCard(
      child: SettingsItem(
        icon: Icons.dark_mode_outlined,
        title: 'Theme',
        trailing: ThemeToggleButton(
          isDarkMode: themeMode == ThemeMode.dark,
          onToggle: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        ),
      ),
    );
  }
}
