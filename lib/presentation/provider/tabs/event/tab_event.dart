import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tabProvider = NotifierProvider.autoDispose<TabEvent, TabController?>(TabEvent.new);
final tabProviderReviewer = NotifierProvider.autoDispose<ReviewerEvent, TabController?>(ReviewerEvent.new);
final indexProvider = NotifierProvider.autoDispose<IndexEvent, int>(IndexEvent.new);

class TabEvent extends Notifier<TabController?> {
  @override
  TabController? build() => null;
  void createController(TickerProvider vsync, int length) {
    final controller = TabController(length: length, vsync: vsync);
    state = controller;

    ref.onDispose(() {
      controller.dispose();
    });
  }
  void jumpTo(int index) => state?.animateTo(index);
}

class ReviewerEvent extends Notifier<TabController?>{
  @override
  TabController? build() {
    return null;
  }

  void createController(TickerProvider vsync, int length) {
    final controller = TabController(length: length, vsync: vsync);
    state = controller;

    ref.onDispose(() {
      controller.dispose();
    });
  }
  
}

class IndexEvent extends Notifier<int> {
  @override
  int build() => 0;

  int changeIndex(int index) => state = index;
}
