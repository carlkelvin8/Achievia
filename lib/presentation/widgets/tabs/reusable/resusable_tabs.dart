import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResusableTabs extends ConsumerStatefulWidget {
  final TabController? controller;
  final List<Tab> tabs;
  const ResusableTabs({super.key, required this.controller, required this.tabs});

  @override
  ConsumerState<ResusableTabs> createState() => _ResusableTabsState();
}

class _ResusableTabsState extends ConsumerState<ResusableTabs> {
  @override
  Widget build(BuildContext context) {
    return TabBar(
          controller: widget.controller,
          tabs: widget.tabs,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall,
        );
  }
}