import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authProvider.notifier).checkSession(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_rounded, size: 80, color: cs.onPrimary),
            const SizedBox(height: 16),
            Text(
              'Avisos ISC',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'CCN',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: cs.onPrimary),
          ],
        ),
      ),
    );
  }
}
