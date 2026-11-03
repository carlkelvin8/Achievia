// ignore_for_file: public_member_api_docs, sort_constructors_first
class ModuleEntity {
  final int id;
  final String title;
  final String description;
  final String userId;
  final String createdAt;
  final String? file;
  final String? image;
  final String status;
  final int subjectId;

  ModuleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
    this.file,
    this.image,
    required this.status,
    required this.subjectId,
  });
}
