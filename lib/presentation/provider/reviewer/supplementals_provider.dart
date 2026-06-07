import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/domain/entities/widgets/pdf_entity.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SupplementalFilter { all, mnemonics, abbreviations, procedures }

final supplementalsProvider =
    NotifierProvider<SupplementalsNotifier, SupplementalsViewState>(
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

  bool shouldShow(SupplementalFilter target) {
    return filter == SupplementalFilter.all || filter == target;
  }

  List<NotesEntity> visibleMnemonics() {
    return _previewItems(SupplementalFilter.mnemonics, mnemonics);
  }

  List<MedicalAbbreviation> visibleAbbreviations() {
    return _previewItems(SupplementalFilter.abbreviations, abbreviations);
  }

  List<PdfEntity> visibleProcedures() {
    return _previewItems(SupplementalFilter.procedures, procedures);
  }

  List<T> _previewItems<T>(SupplementalFilter target, List<T> items) {
    if (filter == target) return items;
    return items.take(4).toList();
  }
}

class SupplementalsNotifier extends Notifier<SupplementalsViewState> {
  late final TextEditingController searchController;

  @override
  SupplementalsViewState build() {
    searchController = TextEditingController();
    ref.onDispose(searchController.dispose);
    return _createState(filter: SupplementalFilter.all, query: '');
  }

  void setFilter(SupplementalFilter filter) {
    state = _createState(filter: filter, query: state.query);
  }

  void setQuery(String value) {
    state = _createState(
      filter: state.filter,
      query: value.trim().toLowerCase(),
    );
  }

  SupplementalsViewState _createState({
    required SupplementalFilter filter,
    required String query,
  }) {
    return SupplementalsViewState(
      filter: filter,
      query: query,
      mnemonics: _filteredMnemonics(query),
      abbreviations: _filteredAbbreviations(query),
      procedures: _filteredProcedures(query),
    );
  }

  List<NotesEntity> _filteredMnemonics(String query) {
    return mnemonics
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();
  }

  List<MedicalAbbreviation> _filteredAbbreviations(String query) {
    return medicalAbbreviations.where((item) {
      return item.abbreviation.toLowerCase().contains(query) ||
          item.expansion.toLowerCase().contains(query);
    }).toList();
  }

  List<PdfEntity> _filteredProcedures(String query) {
    return procedures
        .where((item) => item.text.toLowerCase().contains(query))
        .toList();
  }
}
