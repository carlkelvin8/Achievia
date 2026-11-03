import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/domain/entities/widgets/pdf_entity.dart';

class SupplementalItemDto {
  final int id;
  final int? courseId;
  final String kind;
  final String title;
  final String content;
  final String? imageUrl;
  final String? fileUrl;

  /// The row's `subject_id` (the [courseId] field historically carries the
  /// same value; this one is named for what it is).
  final int? subjectId;

  /// Extra explanation of an abbreviation (its `description` column).
  final String description;

  const SupplementalItemDto({
    required this.id,
    required this.courseId,
    required this.kind,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.fileUrl,
    this.subjectId,
    this.description = '',
  });

  factory SupplementalItemDto.fromJson(Map<String, dynamic> json) {
    return SupplementalItemDto(
      id: int.tryParse(json['id'].toString()) ?? 0,
      courseId: json['course_id'] == null
          ? null
          : int.tryParse(json['course_id'].toString()),
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      fileUrl: json['file_url']?.toString(),
      subjectId: json['subject_id'] == null
          ? null
          : int.tryParse(json['subject_id'].toString()),
    );
  }

  NotesEntity? toMnemonic() {
    if (kind != 'mnemonic') return null;
    return NotesEntity(
      image: imageUrl ?? '',
      title: title,
      content: content,
      fileUrl: fileUrl,
      subjectId: subjectId,
    );
  }

  MedicalAbbreviation? toAbbreviation() {
    if (kind != 'abbreviation') return null;
    return MedicalAbbreviation(
      abbreviation: title,
      expansion: content,
      description: description,
      subjectId: subjectId,
    );
  }

  PdfEntity? toProcedure() {
    if (kind != 'procedure') return null;
    return PdfEntity(text: title, content: content, fileUrl: fileUrl);
  }
}
