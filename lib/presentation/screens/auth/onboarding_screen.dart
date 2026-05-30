import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/headers/header1.dart';
import 'package:achievia/presentation/widgets/headers/header2.dart';
import 'package:achievia/presentation/widgets/headers/sub_header.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60),
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.school,
                      size: 60,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
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
              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    FaIcon(FontAwesomeIcons.facebook, size: 30),
                    SizedBox(width: 16),
                    FaIcon(FontAwesomeIcons.xTwitter, size: 30),
                    SizedBox(width: 16),
                    FaIcon(FontAwesomeIcons.instagram, size: 30),
                    SizedBox(width: 16),
                    FaIcon(FontAwesomeIcons.tiktok, size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
