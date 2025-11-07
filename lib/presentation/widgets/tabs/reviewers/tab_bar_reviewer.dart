import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/tabs_helpers.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/mother_notes_content.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/questions_content_screen.dart';
import 'package:achievia/presentation/screens/screen_contents/contents/supplementals_content_screen.dart';
import 'package:achievia/presentation/widgets/tabs/reusable/resusable_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabBarReviewer extends ConsumerStatefulWidget {
  const TabBarReviewer({super.key});

  @override
  ConsumerState<TabBarReviewer> createState() => _TabBarReviewerState();
}

class _TabBarReviewerState extends ConsumerState<TabBarReviewer> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final notif = ref.read(tabProviderReviewer.notifier);
    final provider = ref.watch(tabProviderReviewer);
    if (provider == null) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        notif.createController(this, 3);
        }
      );
      return const SizedBox();
    }
    return Column(
      children: [
        ResusableTabs(controller: provider, tabs: tabs),
        Expanded(
          child: TabBarView(
            controller: provider,
            children: [
              MotherNotesContent(),
              QuestionsContentScreen(),
              SupplementalsContentScreen(),
            ]
          ),
        )
      ],
    );
  }
}