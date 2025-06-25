import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _userKey = 'auth_user';
  static const _passKey = 'auth_pass';

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _userKey, value: username);
    await _storage.write(key: _passKey, value: password);
  }

  // --- NEW: Specific methods to read credentials for auto-login ---
  Future<String?> readUsername() async {
    return await _storage.read(key: _userKey);
  }

  Future<String?> readPassword() async {
    return await _storage.read(key: _passKey);
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _passKey);
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
