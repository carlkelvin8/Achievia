import 'package:achievia/presentation/provider/reviewer/supplementals_provider.dart';
import 'package:achievia/presentation/widgets/supplementals/abbreviation_list.dart';
import 'package:achievia/presentation/widgets/supplementals/mnemonic_grid.dart';
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
        error: (error, _) =>
            Center(child: Text('Unable to load study aids: $error')),
        data: (state) => SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              SupplementalSearchBar(
                controller: notifier.searchController,
                onChanged: notifier.setQuery,
              ),
              const SizedBox(height: 10),
              SupplementalFilterChips(
                activeFilter: state.filter,
                onSelected: notifier.setFilter,
              ),
              const SizedBox(height: 18),
              if (state.shouldShow(SupplementalFilter.mnemonics))
                SupplementalSection(
                  title: 'Mnemonics',
                  child: MnemonicGrid(items: state.visibleMnemonics()),
                ),
              if (state.shouldShow(SupplementalFilter.abbreviations))
                SupplementalSection(
                  title: 'Abbreviations',
                  child: AbbreviationList(items: state.visibleAbbreviations()),
                ),
              if (state.shouldShow(SupplementalFilter.procedures))
                SupplementalSection(
                  title: 'Procedures',
                  child: ProcedureGrid(items: state.visibleProcedures()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
