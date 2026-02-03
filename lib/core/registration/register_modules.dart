import 'package:achievia/const.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RegisterModules {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(baseUrl: BASE_URL));

  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
