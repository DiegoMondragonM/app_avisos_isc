import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../core/storage/secure_storage.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Usuario usuario;
  /// true solo al crear la cuenta por primera vez → router redirige a /onboarding
  final bool isNewRegistration;
  const AuthAuthenticated(this.usuario, {this.isNewRegistration = false});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial());

  final _service = AuthService.instance;
  final _storage = SecureStorage.instance;

  Future<void> checkSession() async {
    debugPrint('[AUTH] checkSession iniciado');
    state = const AuthLoading();

    try {
      final jwt = await _storage.readJwt();
      debugPrint('[AUTH] JWT: ${jwt == null ? "NO HAY" : "SÍ HAY"}');

      if (jwt == null || jwt.isEmpty) {
        debugPrint('[AUTH] Sin token -> AuthUnauthenticated');
        state = const AuthUnauthenticated();
        return;
      }

      debugPrint('[AUTH] Validando getMe()...');

      final usuario = await _service.getMe().timeout(
        const Duration(seconds: 8),
      );

      debugPrint('[AUTH] Usuario válido -> AuthAuthenticated');
      state = AuthAuthenticated(usuario);

      _setupFcm();
    } catch (e) {
      debugPrint('[AUTH] Error checkSession: $e');
      await _storage.deleteJwt();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthAuthenticated(result.usuario);
      // JWT recién guardado: pedir permisos y registrar token
      _setupFcm();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String nombre,
    required String email,
    required String password,
    int? semestre,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _service.register(
        nombre: nombre,
        email: email,
        password: password,
        semestre: semestre,
      );
      // isNewRegistration=true → el router redirige a /onboarding
      state = AuthAuthenticated(result.usuario, isNewRegistration: true);
      _setupFcm();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Limpia el flag isNewRegistration una vez que el onboarding termina.
  void completarOnboarding() {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(current.usuario);
    }
  }

  Future<void> logout() async {
    try {
      await NotificationService.instance.desactivarToken();
    } catch (_) {}
    await _service.logout();
    state = const AuthUnauthenticated();
  }

  /// Pide permisos de notificación y registra el token FCM.
  /// Solo se llama cuando hay JWT válido.
  void _setupFcm() {
    NotificationService.instance
        .requestPermissionsAndRegisterToken()
        .catchError((e) => debugPrint('[FCM setup] $e'));
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
