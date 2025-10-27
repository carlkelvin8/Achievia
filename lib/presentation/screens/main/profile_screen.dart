import 'package:achievia/presentation/provider/states/tab_service_provider.dart';
import 'package:achievia/presentation/widgets/tabs/profile/tab_bar_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        tabVSyncProvider.overrideWithValue(this),
      ],
      child: Scaffold(
        body: Column(
          children:  [
            Expanded(child: TabBarProfile()),
          ],
        ),
      ),
    );
  }
}