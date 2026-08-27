import 'package:achievia/core/di/injection.dart';
import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/domain/entities/widgets/pdf_entity.dart';
import 'package:achievia/domain/use_cases/reviewer/supplemental_use_case.dart';
import 'package:achievia/presentation/provider/profile/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SupplementalFilter { all, mnemonics, abbreviations, procedures }

final supplementalsProvider =
    AsyncNotifierProvider<SupplementalsNotifier, SupplementalsViewState>(
      SupplementalsNotifier.new,
    );

class SupplementalsViewState {
  final SupplementalFilter filter;
  final String query;
  final List<NotesEntity> mnemonics;
  final List<MedicalAbbreviation> abbreviations;
  final List<PdfEntity> procedures;

  const SupplementalsViewState({
    required this.filter,
    required this.query,
    required this.mnemonics,
    required this.abbreviations,
    required this.procedures,
  });

  bool shouldShow(SupplementalFilter target) =>
      filter == SupplementalFilter.all || filter == target;

  List<NotesEntity> visibleMnemonics() =>
      _previewItems(SupplementalFilter.mnemonics, mnemonics);

  List<MedicalAbbreviation> visibleAbbreviations() =>
      _previewItems(SupplementalFilter.abbreviations, abbreviations);

  List<PdfEntity> visibleProcedures() =>
      _previewItems(SupplementalFilter.procedures, procedures);

  List<T> _previewItems<T>(SupplementalFilter target, List<T> items) =>
      filter == target ? items : items.take(4).toList();
}

class SupplementalsNotifier extends AsyncNotifier<SupplementalsViewState> {
  late final TextEditingController searchController;
  List<NotesEntity> _allMnemonics = const [];
  List<MedicalAbbreviation> _allAbbreviations = const [];
  List<PdfEntity> _allProcedures = const [];

  @override
  Future<SupplementalsViewState> build() async {
    searchController = TextEditingController();
    ref.onDispose(searchController.dispose);

    int? courseId;
    try {
      courseId = (await ref.watch(profileProvider.future)).courseId;
    } catch (_) {
      // The content is still shared and can be loaded without a profile filter.
    }

    final items = await sl<SupplementalUseCase>().getItems(courseId: courseId);
    _setBaseItems(items);
    return _createState(filter: SupplementalFilter.all, query: '');
  }

  void setFilter(SupplementalFilter filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(_createState(filter: filter, query: current.query));
  }

  void setQuery(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      _createState(filter: current.filter, query: value.trim().toLowerCase()),
    );
  }

  void _setBaseItems(List<SupplementalItemDto> items) {
    _allMnemonics = items
        .map((item) => item.toMnemonic())
        .whereType<NotesEntity>()
        .toList();
    _allAbbreviations = items
        .map((item) => item.toAbbreviation())
        .whereType<MedicalAbbreviation>()
        .toList();
    _allProcedures = items
        .map((item) => item.toProcedure())
        .whereType<PdfEntity>()
        .toList();
  }

  SupplementalsViewState _createState({
    required SupplementalFilter filter,
    required String query,
  }) {
    return SupplementalsViewState(
      filter: filter,
      query: query,
      mnemonics: _allMnemonics
          .where((item) => item.title.toLowerCase().contains(query))
          .toList(),
      abbreviations: _allAbbreviations.where((item) {
        return item.abbreviation.toLowerCase().contains(query) ||
            item.expansion.toLowerCase().contains(query);
      }).toList(),
      procedures: _allProcedures
          .where((item) => item.text.toLowerCase().contains(query))
          .toList(),
    );
  }
}
