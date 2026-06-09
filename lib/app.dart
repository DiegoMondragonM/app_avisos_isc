import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/session/session_manager.dart';
import 'providers/auth_provider.dart';
import 'router.dart';
import 'services/notification_service.dart';

class AvisosApp extends ConsumerStatefulWidget {
  const AvisosApp({super.key});

  @override
  ConsumerState<AvisosApp> createState() => _AvisosAppState();
}

class _AvisosAppState extends ConsumerState<AvisosApp> {
  StreamSubscription<void>? _unauthorizedSub;

  // Evita que el logout se ejecute más de una vez si llegan varios 401 en paralelo
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    // Configura handlers de notificación (sin red, sin permisos)
    NotificationService.instance.setupListeners();

    // Callback para navegar al detalle al tocar una notificación
    NotificationService.instance.onNotificationTap = (id) {
      ref.read(routerProvider).push('/publicacion/$id');
    };

    // Escucha 401 globales: token vencido en cualquier llamada autenticada
    _unauthorizedSub =
        SessionManager.instance.onUnauthorized.listen((_) async {
      if (_loggingOut) return;

      final current = ref.read(authProvider);
      if (current is! AuthAuthenticated) return;

      _loggingOut = true;
      try {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu sesión expiró. Inicia sesión de nuevo.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } finally {
        _loggingOut = false;
      }
    });
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Avisos ISC',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: router,
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF1565C0);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
