import 'package:achievia/core/constants/app_paddings.dart';
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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              LoginForm(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
