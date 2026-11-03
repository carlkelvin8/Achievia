import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/utils/mnemonic_filters.dart';
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

  /// Subjects the mnemonics belong to (the choices of the subject filter).
  final List<SupplementalSubject> subjects;

  /// Selected subjects; empty means "All Subjects". Mnemonics and
  /// abbreviations use it.
  final Set<int> selectedSubjectIds;

  const SupplementalsViewState({
    required this.filter,
    required this.query,
    required this.mnemonics,
    required this.abbreviations,
    required this.procedures,
    this.subjects = const [],
    this.selectedSubjectIds = const {},
  });

  bool get hasSubjectFilter => selectedSubjectIds.isNotEmpty;

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
  late TextEditingController searchController;
  List<NotesEntity> _allMnemonics = const [];
  List<MedicalAbbreviation> _allAbbreviations = const [];
  List<PdfEntity> _allProcedures = const [];
  List<SupplementalSubject> _subjects = const [];

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

    // Only filter by courseId if the profile has one set. Items with
    // course_id = null are global items visible to all users regardless.
    final items = await sl<SupplementalUseCase>().getItems(courseId: courseId);
    _setBaseItems(items);
    await _loadSubjects();
    return _createState(filter: SupplementalFilter.all, query: '');
  }

  /// Reloads all study aids after a transient network/database failure.
  Future<void> refresh() async {
    final previous = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      int? courseId;
      try {
        courseId = (await ref.read(profileProvider.future)).courseId;
      } catch (e) {
        debugPrint('Supplementals refresh: profile unavailable: $e');
      }
      final items = await sl<SupplementalUseCase>().getItems(
        courseId: courseId,
      );
      _setBaseItems(items);
      await _loadSubjects();
      return _createState(
        filter: previous?.filter ?? SupplementalFilter.all,
        query: previous?.query ?? '',
        subjectIds: previous?.selectedSubjectIds ?? const {},
      );
    });
  }

  void setFilter(SupplementalFilter filter) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      _createState(
        filter: filter,
        query: current.query,
        subjectIds: current.selectedSubjectIds,
      ),
    );
  }

  void setQuery(String value) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      _createState(
        filter: current.filter,
        query: value.trim().toLowerCase(),
        subjectIds: current.selectedSubjectIds,
      ),
    );
  }

  /// Filters the mnemonics by subject. An empty set is "All Subjects".
  void setSubjectFilter(Set<int> subjectIds) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      _createState(
        filter: current.filter,
        query: current.query,
        subjectIds: subjectIds,
      ),
    );
  }

  /// Resolves subject names for the subjects that mnemonics point to. A
  /// failure here only hides the subject filter; the lists still load.
  Future<void> _loadSubjects() async {
    final ids = {
      for (final item in _allMnemonics)
        if (item.subjectId != null) item.subjectId!,
      for (final item in _allAbbreviations)
        if (item.subjectId != null) item.subjectId!,
    };
    try {
      final titles = await sl<SupplementalUseCase>().getSubjectTitles(ids);
      _subjects = subjectsForMnemonics(
        mnemonics: _allMnemonics,
        abbreviations: _allAbbreviations,
        titlesById: titles,
      );
    } catch (error) {
      debugPrint('Supplementals: subject names unavailable: $error');
      _subjects = const [];
    }
  }

  void _setBaseItems(List<SupplementalItemDto> items) {
    _allMnemonics = sortMnemonicsAlphabetically(
      items.map((item) => item.toMnemonic()).whereType<NotesEntity>(),
    );
    _allAbbreviations = sortAbbreviationsAlphabetically(
      items
          .map((item) => item.toAbbreviation())
          .whereType<MedicalAbbreviation>(),
    );
    _allProcedures = items
        .map((item) => item.toProcedure())
        .whereType<PdfEntity>()
        .toList();
  }

  SupplementalsViewState _createState({
    required SupplementalFilter filter,
    required String query,
    Set<int> subjectIds = const {},
  }) {
    // Only subjects that still exist can stay selected.
    final selected = normalizeSubjectSelection(subjectIds, _subjects);
    return SupplementalsViewState(
      filter: filter,
      query: query,
      subjects: _subjects,
      selectedSubjectIds: selected,
      mnemonics: filterMnemonics(
        items: _allMnemonics,
        query: query,
        subjectIds: selected,
      ),
      abbreviations: filterAbbreviations(
        items: _allAbbreviations,
        query: query,
        subjectIds: selected,
      ),
      procedures: _allProcedures
          .where(
            (item) => InlineHtml.plain(item.text).toLowerCase().contains(query),
          )
          .toList(),
    );
  }
}
