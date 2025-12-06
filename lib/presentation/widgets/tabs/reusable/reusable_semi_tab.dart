import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReusableSemiTab extends ConsumerStatefulWidget {
  final TabController? controller;
  final List<Tab> tabs;
  const ReusableSemiTab({super.key, required this.controller, required this.tabs});

  @override
  ConsumerState<ReusableSemiTab> createState() => _ReusableSemiTabState();
}

class _ReusableSemiTabState extends ConsumerState<ReusableSemiTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: TabBar(
        controller: widget.controller,
        tabs: widget.tabs,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelStyle: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
