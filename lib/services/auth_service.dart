import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/usuario.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = ApiClient.instance;
  final _storage = SecureStorage.instance;

  Future<({String token, Usuario usuario})> register({
    required String nombre,
    required String email,
    required String password,
    int? semestre,
  }) async {
    final res = await _client.post(ApiConstants.register, data: {
      'nombre': nombre,
      'email': email,
      'password': password,
      if (semestre != null) 'semestre': semestre,
    });

    final token = res.data['token'] as String;
    final usuario = Usuario.fromJson(res.data['usuario'] as Map<String, dynamic>);
    await _storage.saveJwt(token);
    return (token: token, usuario: usuario);
  }

  Future<({String token, Usuario usuario})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });

    final token = res.data['token'] as String;
    final usuario = Usuario.fromJson(res.data['usuario'] as Map<String, dynamic>);
    await _storage.saveJwt(token);
    return (token: token, usuario: usuario);
  }

  Future<Usuario> getMe() async {
    final res = await _client.get(ApiConstants.me, withAuth: true);
    return Usuario.fromJson(res.data['usuario'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
