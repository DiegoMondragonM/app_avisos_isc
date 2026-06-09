import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/intereses_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/detail/detail_screen.dart';

/// Puente entre Riverpod y GoRouter.
/// GoRouter se crea UNA SOLA VEZ; refreshListenable avisa cuando re-evaluar redirect.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Cada cambio de authProvider notifica al GoRouter que re-evalúe el redirect.
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  AuthState get _auth => _ref.read(authProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoading = _auth is AuthInitial || _auth is AuthLoading;
    final isAuth = _auth is AuthAuthenticated;
    final loc = state.matchedLocation;

    final onSplash = loc == '/splash';
    final onAuth = loc.startsWith('/auth');

    // Todavía resolviendo sesión → quedarse en splash
    if (isLoading) return onSplash ? null : '/splash';

    // Sin sesión → siempre ir a login (incluso desde splash)
    if (!isAuth && !onAuth) return '/auth/login';

    if (isAuth) {
      final auth = _auth as AuthAuthenticated;

      // Nuevo registro → obligar a pasar por onboarding de intereses
      if (auth.isNewRegistration && loc != '/onboarding') return '/onboarding';

      // Con sesión establecida → salir de splash y pantallas de auth
      if (onAuth || onSplash) return '/home';
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  // ignore: avoid_manual_providers_as_generated_provider_dependency
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,      // Re-evalúa redirect sin recrear el router
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const InteresesScreen(isOnboarding: true),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/publicacion/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DetailScreen(id: id);
        },
      ),
      GoRoute(
        path: '/intereses',
        builder: (_, __) => const InteresesScreen(isOnboarding: false),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
});
