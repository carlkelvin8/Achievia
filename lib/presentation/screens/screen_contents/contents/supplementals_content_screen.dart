import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/presentation/provider/reviewer/supplementals_provider.dart';
import 'package:achievia/presentation/widgets/supplementals/abbreviation_list.dart';
import 'package:achievia/presentation/widgets/supplementals/mnemonic_grid.dart';
import 'package:achievia/presentation/widgets/supplementals/mnemonic_subject_filter.dart';
import 'package:achievia/presentation/widgets/supplementals/procedure_grid.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_filter_chips.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_search_bar.dart';
import 'package:achievia/presentation/widgets/supplementals/supplemental_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupplementalsContentScreen extends ConsumerWidget {
  const SupplementalsContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(supplementalsProvider);
    final notifier = ref.read(supplementalsProvider.notifier);

    return Scaffold(
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52),
              const SizedBox(height: 12),
              const Text('Unable to load study aids'),
              const SizedBox(height: 6),
              Text(userFacingError(error), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: notifier.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) => SafeArea(
          top: false,
          // The search bar, filter icon and chips stay put; only the lists
          // below them scroll.
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SupplementalSearchBar(
                            controller: notifier.searchController,
                            onChanged: notifier.setQuery,
                          ),
                        ),
                        if (state.subjects.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          SubjectFilterButton(
                            active: state.hasSubjectFilter,
                            onPressed: () async {
                              final chosen = await showSubjectFilterDialog(
                                context,
                                subjects: state.subjects,
                                selected: state.selectedSubjectIds,
                              );
                              if (chosen != null) {
                                notifier.setSubjectFilter(chosen);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SupplementalFilterChips(
                      activeFilter: state.filter,
                      onSelected: notifier.setFilter,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  key: const ValueKey('supplementals-list'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  children: [
                    if (state.shouldShow(SupplementalFilter.mnemonics))
                      SupplementalSection(
                        title: 'Mnemonics',
                        child:
                            state.mnemonics.isEmpty &&
                                (state.query.isNotEmpty ||
                                    state.hasSubjectFilter)
                            ? MnemonicEmptyState(
                                searching: state.query.isNotEmpty,
                                filtering: state.hasSubjectFilter,
                                onClearSearch: () {
                                  notifier.searchController.clear();
                                  notifier.setQuery('');
                                },
                                onClearFilter: () =>
                                    notifier.setSubjectFilter(const {}),
                              )
                            : MnemonicGrid(items: state.visibleMnemonics()),
                      ),
                    if (state.shouldShow(SupplementalFilter.abbreviations))
                      SupplementalSection(
                        title: 'Abbreviations',
                        child:
                            state.abbreviations.isEmpty &&
                                (state.query.isNotEmpty ||
                                    state.hasSubjectFilter)
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    state.hasSubjectFilter
                                        ? 'No abbreviations for the selected '
                                              'subjects match your search.'
                                        : 'No abbreviations match your search.',
                                    key: const ValueKey('abbreviation-empty'),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : AbbreviationList(
                                items: state.visibleAbbreviations(),
                              ),
                      ),
                    if (state.shouldShow(SupplementalFilter.procedures))
                      SupplementalSection(
                        title: 'Computations',
                        child: ProcedureGrid(items: state.visibleProcedures()),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
