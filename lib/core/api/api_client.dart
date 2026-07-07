import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pgstay/core/constants/api_constants.dart';

class ApiClient {
  late final Dio dio;
  void Function()? onUnauthorized;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(TokenInterceptor(
      onUnauthorized: () => onUnauthorized?.call(),
    ));

    // Logging interceptor for debugging
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}

class TokenInterceptor extends Interceptor {
  final void Function()? onUnauthorized;

  TokenInterceptor({this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized (e.g., clear token, logout user)
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('auth_token');
      });
      onUnauthorized?.call();
    }
    super.onError(err, handler);
  }
}
