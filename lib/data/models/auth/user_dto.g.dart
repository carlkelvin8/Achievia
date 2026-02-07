// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as num?,
  firstName: json['firstName'] as String?,
  middleName: json['middleName'] as String?,
  lastName: json['lastName'] as String?,
  bio: json['bio'] as String?,
  age: (json['age'] as num?)?.toInt(),
  trial: (json['trial'] as num?)?.toInt(),
  username: json['username'] as String?,
  email: json['email'] as String?,
  password: json['password'] as String?,
  role: json['role'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  status: json['status'] as String?,
  profileImage: json['profileImage'] as String?,
  courseId: (json['courseId'] as num?)?.toInt(),
  token: json['token'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'middleName': instance.middleName,
  'lastName': instance.lastName,
  'bio': instance.bio,
  'age': instance.age,
  'trial': instance.trial,
  'username': instance.username,
  'email': instance.email,
  'password': instance.password,
  'role': instance.role,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'status': instance.status,
  'profileImage': instance.profileImage,
  'courseId': instance.courseId,
  'token': instance.token,
};
