import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legal & Policies section for the Achievia About tab. Each row opens its PDF.
class LegalPoliciesSection extends StatelessWidget {
  const LegalPoliciesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal & Policies',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        _LegalLinkCard(
          title: 'Terms of Service',
          icon: Icons.article_outlined,
          onTap: () => context.push(RouteConstants.termsOfService),
        ),
        const SizedBox(height: 8),
        _LegalLinkCard(
          title: 'Privacy Policy',
          icon: Icons.privacy_tip_rounded,
          onTap: () => context.push(RouteConstants.privacyPolicy),
        ),
      ],
    );
  }
}

/// Same look as the Mission/Vision cards, but opens a page instead of expanding.
class _LegalLinkCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _LegalLinkCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
