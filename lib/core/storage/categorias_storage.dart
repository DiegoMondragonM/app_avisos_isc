import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste localmente las categorías de interés seleccionadas por el usuario.
/// No depende del backend; se guarda en el almacenamiento seguro del dispositivo.
class CategoriasStorage {
  const CategoriasStorage._();
  static const instance = CategoriasStorage._();

  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _key = 'categorias_usuario_v1';

  Future<List<String>> readCategorias() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCategorias(List<String> categorias) async {
    await _storage.write(key: _key, value: jsonEncode(categorias));
  }

  Future<void> deleteCategorias() async {
    await _storage.delete(key: _key);
  }
}
