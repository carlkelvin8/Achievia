import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/dialogs/edit_mantra_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MantraCard extends ConsumerStatefulWidget {
  final String? initialMantra;

  const MantraCard({
    super.key,
    this.initialMantra,
  });

  @override
  ConsumerState<MantraCard> createState() => _MantraCardState();
}

class _MantraCardState extends ConsumerState<MantraCard> {
  late String _mantraText;

  @override
  void initState() {
    super.initState();
    _mantraText = widget.initialMantra ?? '';
  }

  @override
  void didUpdateWidget(covariant MantraCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextMantra = widget.initialMantra ?? '';
    if (nextMantra != oldWidget.initialMantra && nextMantra != _mantraText) {
      _mantraText = nextMantra;
    }
  }

  Future<void> _openEditMantraModal() async {
    final updatedText = await EditMantraDialog.show(
      context,
      initialText: _mantraText,
    );

    if (!mounted || updatedText == null) {
      return;
    }

    final trimmed = updatedText.trim();

    try {
      final message = await ref
          .read(updateMantraProvider.notifier)
          .updateMantra(trimmed);

      if (!mounted) {
        return;
      }

      setState(() {
        _mantraText = trimmed;
      });

      AppToast.showSuccess(context, message);
    } catch (_) {
      // Intentionally no error toast for mantra errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSaving = ref.watch(updateMantraProvider).isLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.spa_outlined,
              color: AppColors.primaryVariant,
              size: 24,
            ),
          ),
          Center(
            child: Text(
              'My Achievian Mantra',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Header

          const SizedBox(height: 8),

          // Description
          Text(
            textAlign: TextAlign.center,
            'Achievian Mantra is a powerful daily affirmation that inspires focus, confidence, and determination in every Achievia user preparing for the board exam.',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 8,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Mantra Text
          Text(
            _mantraText,
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: isSaving ? null : _openEditMantraModal,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: isSaving
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.more_horiz,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
