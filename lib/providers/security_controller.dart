import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import 'providers.dart';

/// Owns the app-lock settings and the actual unlock attempts.
class SecurityController extends AsyncNotifier<SecurityState> {
  final _auth = LocalAuthentication();

  @override
  Future<SecurityState> build() => _load();

  Future<SecurityState> _load() async {
    final store = ref.read(securityStoreProvider);
    var available = false;
    try {
      available = await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on LocalAuthException {
      available = false;
    } on PlatformException {
      available = false;
    }
    return SecurityState(
      hasPin: await store.hasPin,
      lockEnabled: await store.lockEnabled,
      biometricEnabled: await store.biometricEnabled,
      biometricAvailable: available,
    );
  }

  Future<void> _refresh() async {
    state = AsyncValue.data(await _load());
  }

  Future<void> setPin(String pin) async {
    await ref.read(securityStoreProvider).setPin(pin);
    await _refresh();
  }

  Future<bool> verifyPin(String pin) =>
      ref.read(securityStoreProvider).verifyPin(pin);

  Future<void> disableLock() async {
    await ref.read(securityStoreProvider).clearPin();
    await _refresh();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await ref.read(securityStoreProvider).setBiometricEnabled(enabled);
    await _refresh();
  }

  /// Returns true when the platform prompt succeeded. Any platform failure is
  /// treated as "not authenticated" so the PIN stays the fallback.
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Kharcha',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

final securityProvider =
    AsyncNotifierProvider<SecurityController, SecurityState>(SecurityController.new);

/// Whether the lock screen is currently covering the app.
class LockGate extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;
  void unlock() => state = false;
}

final lockGateProvider = NotifierProvider<LockGate, bool>(LockGate.new);
