// ignore_for_file: public_member_api_docs, sort_constructors_first
class NotesEntity {
  final String image;
  final String title;
  final String content;
  final String? fileUrl;

  /// `mnemonics.subject_id`; null for a mnemonic that belongs to no subject.
  final int? subjectId;
  NotesEntity({
    required this.image,
    required this.title,
    this.content = '',
    this.fileUrl,
    this.subjectId,
  });
}
