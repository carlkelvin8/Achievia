import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:achievia/presentation/provider/reviewer/module_provider.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MotherNotesContent extends ConsumerWidget {
  const MotherNotesContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = sl<LocalStorageService>().token ?? '';
    
    final modulesAsync = ref.watch(getModulesProviderState((token: token)));

    return Scaffold(
      body: Padding(
        padding: level1,
        child: modulesAsync.when(
          data: (modules) {
            if (modules.isEmpty) {
              return const Center(
                child: Text('No modules found'),
              );
            }
            
            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: modules.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return PdfBadge(
                        tabType: 'mother notes',
                        text: module.title,
                        imageUrl: module.image,
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading modules',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(getModulesProviderState((token: token))),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}