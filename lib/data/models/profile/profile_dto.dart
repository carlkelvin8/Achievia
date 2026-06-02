import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_dto.g.dart';

@JsonSerializable()
class ProfileResponseDto {
  final bool? success;
  final ProfileDataDto? data;

  ProfileResponseDto({this.success, this.data});

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseDtoToJson(this);
}

@JsonSerializable()
class ProfileDataDto {
  final String? message;
  final ProfileDto? data;

  ProfileDataDto({this.message, this.data});

  factory ProfileDataDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDataDtoToJson(this);
}

@JsonSerializable()
class ProfileDto {
  final String? id;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'middle_name')
  final String? middleName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? bio;
  final String? email;
  final int? age;
  final int? trial;
  final String? username;
  final String? password;
  final String? role;
  final String? university;
  final String? purpose;
  @JsonKey(name: 'date_of_examination')
  final DateTime? dateOfExamination;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final String? status;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'course_id')
  final int? courseId;

  ProfileDto({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.bio,
    this.email,
    this.age,
    this.trial,
    this.username,
    this.password,
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

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);

  ProfileEntity toEntity() => ProfileEntity(
    id: id,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    bio: bio,
    email: email,
    age: age,
    trial: trial,
    username: username,
    role: role,
    university: university,
    purpose: purpose,
    dateOfExamination: dateOfExamination,
    createdAt: createdAt,
    updatedAt: updatedAt,
    status: status,
    profileImage: profileImage,
    courseId: courseId,
  );

  static ProfileDto fromEntity(ProfileEntity entity) {
    return ProfileDto(
      id: entity.id,
      firstName: entity.firstName,
      middleName: entity.middleName,
      lastName: entity.lastName,
      bio: entity.bio,
      email: entity.email,
      age: entity.age,
      trial: entity.trial,
      username: entity.username,
      role: entity.role,
      university: entity.university,
      purpose: entity.purpose,
      dateOfExamination: entity.dateOfExamination,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      status: entity.status,
      profileImage: entity.profileImage,
      courseId: entity.courseId,
    );
  }
}
