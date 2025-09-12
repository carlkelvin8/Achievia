import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/widgets/headers/header1.dart';
import 'package:achievia/presentation/widgets/headers/header2.dart';
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
      body: SingleChildScrollView(
        child: Padding(
          padding: level1,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 60,),
              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: CircleAvatar(),
                ),
              ),
              Center(
                child: Header1(title1: 'Achie', title2: 'via'),
              ),
              Center(
                child: Header2(title: 'AWAKEN ACADEMIC AMBITION',),
              ),
            ],
          ),
        ),
      )
    );
  }
}