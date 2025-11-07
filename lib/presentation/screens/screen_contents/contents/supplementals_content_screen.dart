import 'package:achievia/core/utils/tabs_helpers.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/screens/screen_contents/semi/mnemonics_semi_content.dart';
import 'package:achievia/presentation/widgets/tabs/reusable/reusable_semi_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupplementalsContentScreen extends ConsumerStatefulWidget {
  const SupplementalsContentScreen({super.key});

  @override
  ConsumerState<SupplementalsContentScreen> createState() => _SupplementalsContentScreenState();
}

class _SupplementalsContentScreenState extends ConsumerState<SupplementalsContentScreen>  with TickerProviderStateMixin{
  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tabProviderSemi);
    final tabEvent = ref.read(tabProviderSemi.notifier);
    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_){
      tabEvent.createController(this, 3);
    });
    return const SizedBox();
    }

    return Scaffold(
      body: Column(
          children: [
            ReusableSemiTab(controller: controller, tabs: tabsSemi),
            Expanded(
              child: TabBarView(
                controller: controller,
                children: [
                      MnemonicsSemiContent(),
                      Text('test'),
                      Text('text')
                  ]
                )
            )
          ],
        ),
    );
  }
}