import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: ExamAppBar(title: 'Clinical Chemestry', toolbarheight: 150,),
      persistentFooterAlignment: AlignmentDirectional.center,
      persistentFooterButtons: [
        IconButton(
        onPressed: (){}, 
        icon: Icon(Icons.arrow_back_ios, 
        color: Theme.of(context).primaryColor,)),
        ReusableButton(title: 'UNANSWERED', onPressed: (){}, width: 240, height: 50),
        IconButton(
        onPressed: (){}, 
        icon: Icon(Icons.arrow_forward_ios, 
        color: Theme.of(context).primaryColor,)),
      ],
    );
  }
}