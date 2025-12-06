import 'package:achievia/const.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModules {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: BASE_URL));

  @Named('questions_box')
  Box get questions => Hive.box('questions_box');

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  FlutterSecureStorage get tokenStorage => FlutterSecureStorage();
}



@module
abstract class HiveModule {
  @Named('question_box')
  @preResolve
  Future<Box<QuestionsDto>> openQuestionBox() async {
    return await Hive.openBox<QuestionsDto>('questions_box');
  }
}


