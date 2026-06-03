import 'package:achievia/core/constants/app_paddings.dart';
import 'package:achievia/presentation/provider/reviewer/module_provider.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/badges/pdf_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MotherNotesContent extends ConsumerStatefulWidget {
  const MotherNotesContent({super.key});

  @override
  ConsumerState<MotherNotesContent> createState() => _MotherNotesContentState();
}

class _MotherNotesContentState extends ConsumerState<MotherNotesContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final modulesState = ref.read(paginatedModulesProvider);

    if (!modulesState.hasMore ||
        modulesState.isInitialLoading ||
        modulesState.isLoadingMore ||
        modulesState.errorMessage != null) {
      return;
    }

    if (position.pixels >= position.maxScrollExtent - 250) {
      ref.read(paginatedModulesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMainTab = ref.watch(indexProvider);
    if (activeMainTab != 0) {
      // Avoid creating the pagination provider until Reviewers is active.
      return const SizedBox.shrink();
    }

    final modulesState = ref.watch(paginatedModulesProvider);
    final modulesNotifier = ref.read(paginatedModulesProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: level1,
        child: Builder(
          builder: (context) {
            if (modulesState.isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (modulesState.items.isEmpty &&
                modulesState.errorMessage != null) {
              return Center(
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
                      modulesState.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: modulesNotifier.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (modulesState.items.isEmpty) {
              return const Center(child: Text('No modules found'));
            }

            final totalCount =
                modulesState.items.length +
                (modulesState.isLoadingMore ? 1 : 0);

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: totalCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      if (index >= modulesState.items.length) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        );
                      }

                      final module = modulesState.items[index];
                      return PdfBadge(
                        tabType: 'mother notes',
                        text: module.title,
                        imageUrl: module.image,
                      );
                    },
                  ),
                ),
                if (modulesState.errorMessage != null &&
                    modulesState.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: modulesNotifier.loadMore,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading more'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
