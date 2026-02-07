import 'package:achievia/const.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModules {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: BASE_URL));

  @Named('questions_box')
  Box get questions => Hive.box('questions_box');

  @Named('modules_box')
  Box get modules => Hive.box('modules_box');

  @Named('exam_box')
  Box get exam => Hive.box('exam_box');

  @lazySingleton
  Connectivity get connectivity => Connectivity();
}





