class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Sesión expirada. Inicia sesión de nuevo.'])
      : super(statusCode: 401);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Recurso no encontrado.'])
      : super(statusCode: 404);
}

class ConflictException extends AppException {
  const ConflictException([super.message = 'Ya existe un registro con esos datos.'])
      : super(statusCode: 409);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión a internet. Revisa tu red.']);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Error interno del servidor. Intenta más tarde.'])
      : super(statusCode: 500);
}
