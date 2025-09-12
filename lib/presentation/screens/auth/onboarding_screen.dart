import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/presentation/widgets/headers/header1.dart';
import 'package:achievia/presentation/widgets/headers/header2.dart';
import 'package:achievia/presentation/widgets/headers/sub_header.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  static const _bg = Color(0xFFF5EEFF);
  static const _text = Color(0xFF1E1E1E);

  void _toLogin(BuildContext c) => Navigator.pushNamed(c, '/login');

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD8B4FE), Color(0xFFB39DDB)],
                    ),
                  ),
                ),
                Center(
                  child: Header1(title1: 'Achie', title2: 'via'),
                ),
                Center(child: Header2(title: 'AWAKEN ACADEMIC AMBITION')),
                const SizedBox(height: 20),
                SubHeader(
                  title:
                      "The Philippines' premier e-learning platform for board exam preparation.",
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: headerColor2,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign up still in development')),
                      );
                    },
                    child: const Text('Get Started'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _text,
                      side: const BorderSide(color: Colors.black, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _toLogin(context),
                    child: const Text('I already have an account'),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
