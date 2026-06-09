import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/dispositivos_service.dart';
import '../services/interacciones_service.dart';
import '../core/storage/secure_storage.dart';

/// Handler de background — función top-level, registrada en main.dart ANTES de runApp.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM background] ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  bool _listenersReady = false;

  /// Callback asignado por app.dart para navegar al detalle.
  void Function(int publicacionId)? onNotificationTap;

  // -----------------------------------------------------------------------
  // PASO 1: llamar desde app.dart initState — solo handlers, sin red, sin permisos
  // -----------------------------------------------------------------------
  Future<void> setupListeners() async {
    if (_listenersReady) return;
    _listenersReady = true;

    // Mostrar heads-up en foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Renovación automática de token: solo registra si hay JWT activo
    _fcm.onTokenRefresh.listen((token) {
      SecureStorage.instance.readJwt().then((jwt) {
        if (jwt != null) _registerToken(token);
      });
    });

    // Tap con app en BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Tap con app TERMINADA
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage);
      });
    }

    // Mensaje en FOREGROUND (el sistema ya muestra la notificación)
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM foreground] ${msg.notification?.title}');
    });
  }

  // -----------------------------------------------------------------------
  // PASO 2: llamar SOLO tras autenticación exitosa (login / register / checkSession ok)
  // -----------------------------------------------------------------------
  Future<void> requestPermissionsAndRegisterToken() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');
    await registerCurrentToken();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Registra el token FCM actual en el backend. Requiere JWT activo.
  Future<void> registerCurrentToken() async {
    final token = await _fcm.getToken();
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      await DispositivosService.instance
          .registrarToken(token, plataforma: 'android');
      debugPrint('[FCM] Token registrado en backend');
    } catch (e) {
      debugPrint('[FCM] Error al registrar token: $e');
    }
  }

  Future<void> desactivarToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    try {
      await DispositivosService.instance.desactivarToken(token);
    } catch (e) {
      debugPrint('[FCM] Error al desactivar token: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final idStr = message.data['publicacion_id'] as String?;
    if (idStr == null) return;
    final id = int.tryParse(idStr);
    if (id == null) return;

    SecureStorage.instance.readJwt().then((jwt) {
      if (jwt != null) {
        InteraccionesService.instance.registrar(id, TipoEvento.tapNotification);
      }
    });

    onNotificationTap?.call(id);
  }
}
