import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/forms/login_form.dart';
import 'package:achievia/presentation/widgets/headers/core/header1.dart';
import 'package:achievia/presentation/widgets/headers/core/header2.dart';
import 'package:achievia/presentation/widgets/headers/core/sub_header.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60),
              // Official Achievia logo (vector, so it stays sharp at any
              // density). The artwork fills about 74% of its square canvas;
              // a 150 box shows it at roughly the old badge's visual size.
              const Center(
                child: InlineStyleSvg(
                  key: ValueKey('login-logo'),
                  assetPath: logo,
                  width: 150,
                  height: 150,
                  semanticsLabel: 'Achievia logo',
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
              LoginForm(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
