import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/security_controller.dart';
import 'pin_pad.dart';
import '../../core/theme/app_palette.dart';

const int kPinLength = 4;

/// Covers the whole app until the PIN or a fingerprint checks out.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  String _entry = '';
  bool _error = false;
  bool _checking = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    final state = ref.read(securityProvider).value;
    if (state == null || !state.biometricEnabled || !state.biometricAvailable) {
      return;
    }
    final ok = await ref
        .read(securityProvider.notifier)
        .authenticateWithBiometrics();
    if (ok && mounted) ref.read(lockGateProvider.notifier).unlock();
  }

  Future<void> _onDigit(String d) async {
    if (_checking || _entry.length >= kPinLength) return;
    setState(() {
      _entry += d;
      _error = false;
    });
    if (_entry.length == kPinLength) await _submit();
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await ref.read(securityProvider.notifier).verifyPin(_entry);
    if (!mounted) return;
    if (ok) {
      ref.read(lockGateProvider.notifier).unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    setState(() {
      _error = true;
      _entry = '';
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final security = ref.watch(securityProvider).value;
    final canBio =
        (security?.biometricEnabled ?? false) &&
        (security?.biometricAvailable ?? false);

    return Scaffold(
      backgroundColor: p.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Kharcha is locked',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ? 'Wrong PIN. Try again.' : 'Enter your PIN to continue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _error ? p.expense : p.inkSoft,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                // Three quick oscillations, decaying to nothing.
                final t = _shake.value;
                final dx = (1 - t) * 12 * (t == 0 ? 0 : _oscillate(t));
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: PinDots(
                length: kPinLength,
                filled: _entry.length,
                error: _error,
              ),
            ),
            const Spacer(),
            PinPad(
              onDigit: _onDigit,
              onBackspace: () => setState(() {
                if (_entry.isNotEmpty) {
                  _entry = _entry.substring(0, _entry.length - 1);
                }
                _error = false;
              }),
              onBiometric: canBio ? _tryBiometrics : null,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  static double _oscillate(double t) {
    const cycles = 3;
    return (t * cycles * 2 % 2 < 1 ? 1 : -1).toDouble();
  }
}
