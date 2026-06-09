import '../core/constants/api_constants.dart';
import '../core/db/database_helper.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/publicacion.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _client = ApiClient.instance;
  final _db = DatabaseHelper.instance;
  final _storage = SecureStorage.instance;

  /// Ejecuta la sincronización incremental (o completa si es primera vez).
  Future<int> sync() async {
    final since = await _storage.readSyncAt();

    final res = await _client.get(
      ApiConstants.syncPublicaciones,
      queryParameters: since != null ? {'since': since} : null,
    );

    final data = res.data as Map<String, dynamic>;
    final syncAt = data['sync_at'] as String;
    final items = data['publicaciones'] as List<dynamic>;

    int cambios = 0;
    for (final item in items) {
      final p = Publicacion.fromJson(item as Map<String, dynamic>);
      if (p.syncAction == 'upsert') {
        await _db.upsertPublicacion(p.toDbMap());
        cambios++;
      } else if (p.syncAction == 'remove') {
        await _db.removePublicacion(p.id);
        cambios++;
      }
    }

    // Solo actualizamos el cursor si todo fue exitoso
    await _storage.saveSyncAt(syncAt);
    return cambios;
  }

  Future<List<Publicacion>> getPublicacionesLocales() async {
    final rows = await _db.getPublicaciones();
    return rows.map(Publicacion.fromJson).toList();
  }

  /// Devuelve publicaciones de la caché cuya lista de tags incluye
  /// AL MENOS UNO de los [slugs] de intereses del usuario.
  Future<List<Publicacion>> getPublicacionesPorIntereses(
      List<String> slugs) async {
    if (slugs.isEmpty) return getPublicacionesLocales();
    final rows = await _db.getPublicacionesByTagSlugs(slugs);
    return rows.map(Publicacion.fromJson).toList();
  }

  Future<Publicacion?> getPublicacionLocal(int id) async {
    final row = await _db.getPublicacion(id);
    if (row == null) return null;
    return Publicacion.fromJson(row);
  }
}
