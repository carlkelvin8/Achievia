import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/list_items/expandable_item.dart';
import 'package:flutter/material.dart';

class AchieviaContentScreen extends StatefulWidget {
  const AchieviaContentScreen({super.key});

  @override
  State<AchieviaContentScreen> createState() => _AchieviaContentScreenState();
}

class _AchieviaContentScreenState extends State<AchieviaContentScreen> {
  final Map<int, bool> _expandedItems = {
    0: true,
  }; // First item expanded by default

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievia Introduction Card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 20),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Achie',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    TextSpan(
                                      text: 'via',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'AWAKEN ACADEMIC AMBITION',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Achievia is a modern review platform designed to help students study smarter and excel in board exams through a convenient, innovative, and effective approach. Achievia offers curated materials and tools tailored to meet the needs of future board passers. With a growing community of dedicated users called Achievians, the platform continues to redefine how students prepare — with focus, flexibility, and results.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // The Meaning Behind the Achievia Logo Section
              Text(
                'The Meaning Behind the Achievia Logo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Expandable Items
              ExpandableItem(
                title: 'Official Logo',
                description:
                    'The letter A symbolizes not just our name, but our aim for excellence — to help learners become A+ achievers. It stands tall, representing ambition, aspiration, and the start of a successful academic journey.',
                isExpanded: _expandedItems[0] ?? false,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItems[0] = expanded;
                  });
                },
                imagePath: 'assets/images/logo.png',
              ),
              const SizedBox(height: 8),
              ExpandableItem(
                title: 'Peak',
                description: '',
                isExpanded: _expandedItems[1] ?? false,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItems[1] = expanded;
                  });
                },
                imagePath: 'assets/images/logo.png',
              ),
              const SizedBox(height: 8),
              ExpandableItem(
                title: 'Ups and Downs',
                description: '',
                isExpanded: _expandedItems[2] ?? false,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItems[2] = expanded;
                  });
                },
                imagePath: 'assets/images/logo.png',
              ),
              const SizedBox(height: 8),
              ExpandableItem(
                title: 'Mistakes and Curiosity',
                description: '',
                isExpanded: _expandedItems[3] ?? false,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItems[3] = expanded;
                  });
                },
                imagePath: 'assets/images/logo.png',
              ),
              const SizedBox(height: 8),
              ExpandableItem(
                title: 'Corrections and Improvements',
                description: '',
                isExpanded: _expandedItems[4] ?? false,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItems[4] = expanded;
                  });
                },
                imagePath: 'assets/images/logo.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
