import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/network_image_with_fallback.dart';
import 'package:flutter/material.dart';

class ProfileStatusCard extends StatelessWidget {
  final String lastName;
  final String firstName;
  final String middleName;
  final String university;
  final String purpose;
  final String dateOfExam;
  final String profileImageUrl;

  const ProfileStatusCard({
    super.key,
    this.lastName = 'N/A',
    this.firstName = 'N/A',
    this.middleName = 'N/A',
    this.university = 'N/A',
    this.purpose = 'N/A',
    this.dateOfExam = 'N/A',
    this.profileImageUrl = '',
  });

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '► ',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
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
    final width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final stars = List.generate(
      3,
      (index) => Icon(Icons.star, color: Colors.amber.shade700, size: 13),
    );

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
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImageWithFallback(
                      imageUrl: profileImageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      fallbackIcon: Icons.person,
                      fallbackIconSize: 56,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        context,
                        'LAST NAME',
                        lastName,
                      ),
                      _buildDetailRow(
                        context,
                        'FIRST NAME',
                        firstName,
                      ),
                      _buildDetailRow(
                        context,
                        'MIDDLE NAME',
                        middleName,
                      ),
                      _buildDetailRow(
                        context,
                        'UNIVERSITY',
                        university,
                      ),
                      _buildDetailRow(
                        context,
                        'PURPOSE',
                        purpose,
                      ),
                      _buildDetailRow(
                        context,
                        'DATE OF EXAM',
                        dateOfExam,
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.success,
            child: Text(
              purpose,
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
    );
  }
}
