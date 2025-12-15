import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:achievia/presentation/widgets/settings/settings_card.dart';
import 'package:achievia/presentation/widgets/inputs/text_size_slider.dart';

/// Text size settings section with slider control
class TextSizeSettingsSection extends ConsumerWidget {
  const TextSizeSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(textSizeProvider);

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsItem(icon: Icons.text_fields, title: 'Text Size'),
          const SizedBox(height: 16),
          TextSizeSlider(
            value: textSize,
            onChanged: (value) {
              ref.read(textSizeProvider.notifier).state = value;
            },
            description:
                'Text Size lets you adjust the font size for a more comfortable reading experience. Customize it to suit your preference and reduce eye strain while studying.',
          ),
        ],
      ),
    );
  }
}
