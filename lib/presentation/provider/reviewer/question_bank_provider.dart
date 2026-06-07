import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/domain/entities/widgets/questions_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final questionBankItemsProvider = Provider<List<QuestionsEntityWidget>>((ref) {
  return questions;
});
