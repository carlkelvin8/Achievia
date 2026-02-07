import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/loading_indicators.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/network_image_with_fallback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProfileStatusCard extends ConsumerStatefulWidget {
  const ProfileStatusCard({super.key});

  @override
  ConsumerState<ProfileStatusCard> createState() => _ProfileStatusCardState();
}

class _ProfileStatusCardState extends ConsumerState<ProfileStatusCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).fetchProfile();
    });
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ).copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            '► ',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatExamDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatPurpose(String? purpose) {
    if (purpose == null || purpose.isEmpty) return 'N/A';
    return purpose.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(profileProvider);

    final stars = List.generate(
      3,
      (index) => Icon(Icons.star, color: Colors.amber.shade700, size: 13),
    );

    return profileAsync.when(
      data: (profile) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        width: width,
        child: Column(
          children: [
            // Header
            Padding(
              padding: level1_widget,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', width: 40, height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Republic of the Philippines',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'ACHIEVIA REVIEW',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryVariant,
                              ),
                        ),
                        Text(
                          'PROFESSIONAL IDENTIFICATION CARD',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Row(children: stars),
                ],
              ),
            ),

            const Divider(height: 1),

            // Body
            Padding(
              padding: level1_widget,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkImageWithFallback(
                        imageUrl: profile.profileImage ?? '',
                        width: 85,
                        height: 85,
                        errorWidget: Icon(
                          Icons.person,
                          size: 42,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailRow(
                          context,
                          'LAST NAME',
                          (profile.lastName ?? '').toUpperCase(),
                        ),
                        _buildDetailRow(
                          context,
                          'FIRST NAME',
                          (profile.firstName ?? '').toUpperCase(),
                        ),
                        _buildDetailRow(
                          context,
                          'MIDDLE NAME',
                          (profile.middleName ?? '').toUpperCase(),
                        ),
                        _buildDetailRow(
                          context,
                          'UNIVERSITY',
                          (profile.university ?? 'N/A').toUpperCase(),
                        ),
                        _buildDetailRow(
                          context,
                          'PURPOSE',
                          _formatPurpose(profile.purpose),
                        ),
                        _buildDetailRow(
                          context,
                          'DATE OF EXAM',
                          _formatExamDate(profile.dateOfExamination),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.success,
              child: Text(
                _formatPurpose(profile.purpose),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Barcode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  'https://imgs.search.brave.com/YqFfU8CSBKMHpPVf6q72dWwX86OHj1IghUb5g9fYBPU/rs:fit:0:180:1:0/g:ce/aHR0cHM6Ly93d3cu/YmFyY29kZXJlc291/cmNlLmNvbS9pbWFn/ZXMvQ29kZTM5QmFy/Y29kZS5qcGc',
                  height: 40,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        width: width,
        padding: const EdgeInsets.all(40),
        child: const Center(child: LoadingIndicator()),
      ),
      error: (error, stack) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error),
        ),
        width: width,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 40),
            const SizedBox(height: 8),
            Text(
              'Failed to load profile',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
