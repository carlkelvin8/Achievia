import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/widgets/grids/reusable_grids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:level1,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            ReusableGrids(crossAxisCount: 3, itemCount: notes.length, text: 'Saved Rationalizatiions',icon: Icons.filter_list, today: 'Today', yesterday: 'Yesterday', itemCount2: notes2.length,)
            ],
          ),
        )
    );
  }
}