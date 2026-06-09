import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../session/session_manager.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool withAuth = false,
  }) async {
    try {
      final options = await _buildOptions(withAuth: withAuth);
      return await _dio.get(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    bool withAuth = false,
  }) async {
    try {
      final options = await _buildOptions(withAuth: withAuth);
      return await _dio.post(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    bool withAuth = false,
  }) async {
    try {
      final options = await _buildOptions(withAuth: withAuth);
      return await _dio.put(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    bool withAuth = false,
  }) async {
    try {
      final options = await _buildOptions(withAuth: withAuth);
      return await _dio.delete(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Options> _buildOptions({required bool withAuth}) async {
    if (!withAuth) return Options();
    final jwt = await SecureStorage.instance.readJwt();
    if (jwt == null) throw const UnauthorizedException();
    return Options(headers: {'Authorization': 'Bearer $jwt'});
  }

  AppException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);

    if (statusCode == 401) {
      SessionManager.instance.notifyUnauthorized();
      return UnauthorizedException(message ?? 'Token inválido o expirado');
    }

    return switch (statusCode) {
      404 => NotFoundException(message ?? 'Recurso no encontrado'),
      409 => ConflictException(message ?? 'Conflicto con un registro existente'),
      500 => const ServerException(),
      _ => AppException(message ?? 'Error inesperado', statusCode: statusCode),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) return data['error'] as String?;
    return null;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    handler.next(options);
  }
}
