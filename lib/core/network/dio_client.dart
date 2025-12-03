import 'package:achievia/const.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_plus/dio_cache_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: BASE_URL,
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    headers: {
      "Content-Type":"application/json"
    }
  )
);

final cache = SharedPreferencesWithCacheOptions(
  
);


