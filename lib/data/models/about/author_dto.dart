import 'package:achievia/domain/entities/widgets/author_entity.dart';

class AuthorDto {
  final String image;
  final String name;
  final String university;
  final String achievement;
  final String greeting;
  final String message;

  const AuthorDto({
    required this.image,
    required this.name,
    required this.university,
    required this.achievement,
    required this.greeting,
    required this.message,
  });

  factory AuthorDto.fromJson(Map<String, dynamic> json) => AuthorDto(
    image: json['image_url']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    university: json['university']?.toString() ?? '',
    achievement: json['achievement']?.toString() ?? '',
    greeting: json['greeting']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
  );

  AuthorEntity toEntity() => AuthorEntity(
    image: image,
    name: name,
    university: university,
    achievement: achievement,
    greeting: greeting,
    message: message,
  );
}
