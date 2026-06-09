import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  const SecureStorage._();
  static const SecureStorage instance = SecureStorage._();

  static final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyJwt = 'jwt_token';
  static const _keySyncAt = 'last_sync_at';

  Future<void> saveJwt(String token) =>
      _storage.write(key: _keyJwt, value: token);

  Future<String?> readJwt() => _storage.read(key: _keyJwt);

  Future<void> deleteJwt() => _storage.delete(key: _keyJwt);

  Future<void> saveSyncAt(String isoDate) =>
      _storage.write(key: _keySyncAt, value: isoDate);

  Future<String?> readSyncAt() => _storage.read(key: _keySyncAt);

  Future<void> deleteSyncAt() => _storage.delete(key: _keySyncAt);

  Future<void> clearAll() => _storage.deleteAll();
}
