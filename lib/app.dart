import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/lock/lock_gate_view.dart';
import 'providers/providers.dart';

class KharchaApp extends ConsumerWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Defaults to System, so the phone's own setting still wins unless
      // someone deliberately overrides it here.
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      home: const LockGateView(),
      builder: (context, child) {
        // Keep the layout predictable regardless of the system font scale.
        final scale = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.85, maxScaleFactor: 1.2);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scale),
          child: child!,
        );
      },
    );
  }
}
