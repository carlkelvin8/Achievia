import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingMockboardScreen extends ConsumerStatefulWidget {
  final String title;
  const OnboardingMockboardScreen({required this.title,super.key});

  @override
  ConsumerState<OnboardingMockboardScreen> createState() => _OnboardingMockboardScreenState();
}

class _OnboardingMockboardScreenState extends ConsumerState<OnboardingMockboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mock Boards',
        style: GoogleFonts.poppins(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600
        ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: level1_widget,
      ),
    );
  }
}