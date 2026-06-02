class ProfileEntity {
  final String? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? bio;
  final String? email;
  final int? age;
  final int? trial;
  final String? username;
  final String? role;
  final String? university;
  final String? purpose;
  final DateTime? dateOfExamination;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? profileImage;
  final int? courseId;

  const ProfileEntity({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.bio,
    this.email,
    this.age,
    this.trial,
    this.username,
    this.role,
    this.university,
    this.purpose,
    this.dateOfExamination,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.profileImage,
    this.courseId,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  ProfileEntity copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? email,
    int? age,
    int? trial,
    String? username,
    String? role,
    String? university,
    String? purpose,
    DateTime? dateOfExamination,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? profileImage,
    int? courseId,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      age: age ?? this.age,
      trial: trial ?? this.trial,
      username: username ?? this.username,
      role: role ?? this.role,
      university: university ?? this.university,
      purpose: purpose ?? this.purpose,
      dateOfExamination: dateOfExamination ?? this.dateOfExamination,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      courseId: courseId ?? this.courseId,
    );
  }
}
