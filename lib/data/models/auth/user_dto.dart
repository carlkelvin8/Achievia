// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_dto.g.dart';
@JsonSerializable()
class UserDto {
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
  UserDto({
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

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  factory UserDto.fromJson(Map<String, dynamic> map) => _$UserDtoFromJson(map);

  static UserDto fromEntity(UserEntity entity) => UserDto(id: entity.id, firstName: entity.firstName, middleName: entity.middleName, lastName: entity.lastName, bio: entity.bio, age: entity.age, username: entity.username, email: entity.email, password:entity. password, role: entity.role, status: entity.status, profileImage: entity.profileImage);

  UserEntity toEntity() => UserEntity(id: id, firstName: firstName, middleName: middleName, lastName: lastName, bio: bio, age: age, username: username, email: email, password: password, role: role, status: status, profileImage: profileImage);
}
