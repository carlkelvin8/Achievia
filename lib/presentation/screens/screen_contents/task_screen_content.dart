import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/presentation/widgets/grids/grid_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskScreenContent extends ConsumerStatefulWidget {
  const TaskScreenContent({super.key});

  @override
  ConsumerState<TaskScreenContent> createState() => _TaskScreenContentState();
}

class _TaskScreenContentState extends ConsumerState<TaskScreenContent> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: level2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  [
              GridCards(),
              SizedBox(height: 20),
              Text(
                      'My Achievian Goal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              SizedBox(height: 10),
              Container(
                padding: level2_widget,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSecondary,
                  borderRadius: BorderRadius.all(Radius.circular(10))
                ),
                width: width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt,color: Theme.of(context).colorScheme.primary,),
                        const SizedBox(width: 5,),
                        Text('Reminders',
                        style: Theme.of(context).textTheme.labelMedium,
                        )
                      ],
                    ),
                  Text('3', 
                  style: Theme.of(context).textTheme.labelMedium,
                  )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}