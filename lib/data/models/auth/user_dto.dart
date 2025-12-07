// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';
@JsonSerializable()
class UserDto {
  final num? id;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? bio;
  final int? age;
  final int? trial;
  final String? username;
  final String? email;
  final String? password;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? profileImage;
  final int? courseId;
  final String? token;
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
  });

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  factory UserDto.fromJson(Map<String, dynamic> map) => _$UserDtoFromJson(map);

  static UserDto fromEntity(UserEntity entity) => UserDto(id: entity.id, firstName: entity.firstName, middleName: entity.middleName, lastName: entity.lastName, bio: entity.bio, age: entity.age, username: entity.username, email: entity.email, password: entity.password, role: entity.role, status: entity.status, profileImage: entity.profileImage);

  UserEntity toEntity() => UserEntity(id: id, firstName: firstName, middleName: middleName, lastName: lastName, bio: bio, age: age, username: username, email: email, password: password, role: role, status: status, profileImage: profileImage);
}
