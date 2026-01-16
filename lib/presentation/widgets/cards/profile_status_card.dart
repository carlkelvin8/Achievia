import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
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
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ).copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            '► ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;
    final width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final stars = List.generate(
      3,
      (index) => Icon(Icons.star, color: Colors.amber.shade700, size: 13),
    );

    // Format date of examination
    String formattedExamDate = 'N/A';
    if (profile?.dateOfExamination != null) {
      formattedExamDate = DateFormat('MMMM yyyy').format(profile!.dateOfExamination!).toUpperCase();
    }

    // Profile image URL
    final profileImageUrl = profile?.profileImage ??
        'https://imgs.search.brave.com/06y_UGpqC2WO7A0wUNodf1gbBVQFeVd4B6Wx2VLw8oQ/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9jZG4u/dmVjdG9yc3RvY2su/Y29tL2kvNTAwcC8y/Ni80MC9wcm9maWxl/LXBsYWNlaG9sZGVy/LWltYWdlLWdyYXkt/c2lsaG91ZXR0ZS12/ZWN0b3ItMjIxMjI2/NDAuanBn';

    if (profileState.isLoading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        width: width,
        height: 300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'ACHIEVIA REVIEW',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryVariant,
                        ),
                      ),
                      Text(
                        'PROFESSIONAL IDENTIFICATION CARD',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  width: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(context, 'LAST NAME', profile?.lastName?.toUpperCase() ?? 'N/A'),
                      _buildDetailRow(context, 'FIRST NAME', profile?.firstName?.toUpperCase() ?? 'N/A'),
                      _buildDetailRow(context, 'MIDDLE NAME', profile?.middleName?.toUpperCase() ?? 'N/A'),
                      _buildDetailRow(context, 'UNIVERSITY', profile?.university?.toUpperCase() ?? 'N/A'),
                      _buildDetailRow(context, 'PURPOSE', profile?.purpose?.toUpperCase() ?? 'N/A'),
                      _buildDetailRow(context, 'DATE OF EXAM', formattedExamDate),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.success,
            child: Text(
              'MEDICAL TECHNOLOGIST',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Barcode
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Image.network(
                'https://imgs.search.brave.com/YqFfU8CSBKMHpPVf6q72dWwX86OHj1IghUb5g9fYBPU/rs:fit:0:180:1:0/g:ce/aHR0cHM6Ly93d3cu/YmFyY29kZXJlc291/cmNlLmNvbS9pbWFn/ZXMvQ29kZTM5QmFy/Y29kZS5qcGc',
                height: 50,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
