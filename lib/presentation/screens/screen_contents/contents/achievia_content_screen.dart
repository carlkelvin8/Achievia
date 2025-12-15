import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/cards/achievia_intro_card.dart';
import 'package:achievia/presentation/widgets/list_items/logo_meaning_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchieviaContentScreen extends ConsumerWidget {
  const AchieviaContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievia Introduction Card
              AchieviaIntroCard(),
              SizedBox(height: 32),

              // Logo Meaning Section
              LogoMeaningSection(),
            ],
          ),
        ),
      ),
    );
  }
}
