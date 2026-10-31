import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/security_controller.dart';
import '../shell/app_shell.dart';
import 'lock_screen.dart';

/// Decides whether the app or the lock screen is on top, and re-locks when the
/// app has been in the background.
class LockGateView extends ConsumerStatefulWidget {
  const LockGateView({super.key});

  @override
  ConsumerState<LockGateView> createState() => _LockGateViewState();
}

class _LockGateViewState extends ConsumerState<LockGateView>
    with WidgetsBindingObserver {
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }
    final security = ref.read(securityProvider).value;
    if (security?.lockEnabled ?? false) {
      ref.read(lockGateProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = ref.watch(securityProvider);
    final locked = ref.watch(lockGateProvider);

    // On the very first resolve, lock immediately if the user has enabled it.
    if (!_initialised && security.hasValue) {
      _initialised = true;
      if (security.value!.lockEnabled) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(lockGateProvider.notifier).lock(),
        );
      }
    }

    final showLock = (security.value?.lockEnabled ?? false) && locked;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      // The default layout builder uses a loose Stack, which would let the
      // Scaffold below collapse to zero height. Force it to fill instead.
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: showLock ? const LockScreen() : const AppShell(),
    );
  }
}
