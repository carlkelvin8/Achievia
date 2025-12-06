// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserEntity {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String bio;
  final int age;
  final int? trial;
  final String username;
  final String email;
  final String password;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;
  final String profileImage;
  final int? courseId;
  UserEntity({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.bio,
    required this.age,
    this.trial,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.createdAt,
    this.updatedAt,
    required this.status,
    required this.profileImage,
    this.courseId,
  });
}
