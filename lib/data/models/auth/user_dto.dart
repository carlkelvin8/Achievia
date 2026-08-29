// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:injectable/injectable.dart';

part 'user_dto.g.dart';

@JsonSerializable()
@injectable
@lazySingleton
class UserDto {
  final num? id;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'middle_name')
  final String? middleName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? bio;
  final int? age;
  final int? trial;
  final String? username;
  final String? email;
  final String? password;
  final String? role;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  final String? status;
  @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'courseId')
  final int? courseId;
  final String? token;
  final String? university;
  final String? purpose;
  @JsonKey(name: 'date_of_examination')
  final DateTime? dateOfExamination;
  UserDto({
    this.id,
    this.firstName,
    this.middleName,
    this.lastName,
    this.bio,
    this.age,
    this.trial,
    this.username,
    this.email,
    this.password,
    this.role,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.profileImage,
    this.courseId,
    this.token,
    this.university,
    this.purpose,
    this.dateOfExamination,
  });

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  factory UserDto.fromJson(Map<String, dynamic> map) => _$UserDtoFromJson(map);

  static UserDto fromEntity(UserEntity entity) => UserDto(
    id: entity.id,
    firstName: entity.firstName,
    middleName: entity.middleName,
    lastName: entity.lastName,
    bio: entity.bio,
    age: entity.age,
    username: entity.username,
    email: entity.email,
    password: entity.password,
    role: entity.role,
    courseId: entity.courseId,
    status: entity.status,
    profileImage: entity.profileImage,
    university: entity.university,
    purpose: entity.purpose,
    dateOfExamination: entity.dateOfExamination,
  );

  UserEntity toEntity() => UserEntity(
    id: id,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    bio: bio,
    age: age,
    username: username,
    email: email,
    password: password,
    role: role,
    status: status,
    profileImage: profileImage,
    courseId: courseId,
    university: university,
    purpose: purpose,
    dateOfExamination: dateOfExamination,
  );
}
