import 'package:achievia/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final tabServiceProvider = Provider.autoDispose<TabControllerService>((ref) {
  return sl<TabControllerService>();
});

final tabIndexProvider = StateProvider.autoDispose<int>((ref) {
  final tabService = ref.watch(tabServiceProvider);
  return tabService.currentIndex;
});

final tabVSyncProvider = Provider<TickerProvider>((ref) {
  throw UnimplementedError('tabVSyncProvider must be overridden');
});


final tabControllerProvider = Provider.autoDispose<TabController>((ref){
  final vsync = ref.watch(tabVSyncProvider);
  final controller = TabController(length: 4, vsync: vsync);
  ref.onDispose((){
    controller.dispose();
  });
  return controller;
});

class TabControllerService {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void changeTab(int index) {
    _currentIndex = index;
  }
}