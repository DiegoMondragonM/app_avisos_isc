class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://163.192.134.248/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Tags
  static const String tags = '/tags';
  static const String misIntereses = '/tags/mis-intereses';

  // Publicaciones
  static const String publicaciones = '/publicaciones';
  static String publicacionDetalle(int id) => '/publicaciones/$id';

  // Sync
  static const String syncPublicaciones = '/sync/publicaciones';

  // Dispositivos
  static const String dispositivosToken = '/dispositivos/token';

  // Interacciones
  static const String interacciones = '/interacciones';

  // Health
  static const String health = '/health';
}
