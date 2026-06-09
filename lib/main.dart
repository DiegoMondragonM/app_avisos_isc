import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale español para DateFormat
  await initializeDateFormatting('es', null);

  // Firebase core — obligatorio antes de usar cualquier servicio Firebase
  await Firebase.initializeApp();

  // El handler de background DEBE registrarse antes de runApp,
  // pero NO hace llamadas a la red ni pide permisos.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: AvisosApp(),
    ),
  );
}
