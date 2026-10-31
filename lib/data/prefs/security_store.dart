import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-lock state. The PIN is never stored in the clear: we keep a random salt
/// and a SHA-256 digest of salt+PIN, inside Keystore-backed secure storage.
class SecurityStore {
  /// v11 of the plugin encrypts with AES-GCM behind the Keystore by default,
  /// so no extra Android options are needed here.
  SecurityStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kLockEnabled = 'lock_enabled';
  static const _kBiometric = 'biometric_enabled';

  Future<bool> get hasPin async => (await _storage.read(key: _kHash)) != null;

  Future<bool> get lockEnabled async =>
      (await _storage.read(key: _kLockEnabled)) == 'true' && await hasPin;

  Future<bool> get biometricEnabled async =>
      (await _storage.read(key: _kBiometric)) == 'true';

  Future<void> setLockEnabled(bool v) =>
      _storage.write(key: _kLockEnabled, value: v.toString());

  Future<void> setBiometricEnabled(bool v) =>
      _storage.write(key: _kBiometric, value: v.toString());

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _digest(salt, pin));
    await setLockEnabled(true);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final hash = await _storage.read(key: _kHash);
    if (salt == null || hash == null) return false;
    return _constantTimeEquals(_digest(salt, pin), hash);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kHash);
    await setLockEnabled(false);
    await setBiometricEnabled(false);
  }

  static String _digest(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _randomSalt() {
    final rng = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => rng.nextInt(256)));
  }

  /// Avoids leaking how many leading characters matched via timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
