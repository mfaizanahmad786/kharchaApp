import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../providers/providers.dart';
import '../../providers/security_controller.dart';
import '../lock/pin_setup_sheet.dart';
import '../shell/bottom_nav.dart';
import 'manage_screens.dart';
import 'widgets/settings_tiles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final security = ref.watch(securityProvider).value ?? SecurityState.unknown;
    final balance = ref.watch(balanceProvider).value ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              kNavBarScrollPadding,
            ),
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              _ProfileCard(
                name: settings.userName,
                balance: balance,
                onEdit: () => _editName(context, ref, settings.userName),
              ),
              const SizedBox(height: 24),

              SettingsGroup(
                title: 'Preferences',
                children: [
                  SettingsSwitch(
                    icon: Icons.visibility_off_rounded,
                    iconColor: AppColors.catIndigo,
                    title: 'Hide amounts',
                    subtitle: 'Mask every figure on screen',
                    value: settings.hideAmounts,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setHideAmounts(v),
                  ),
                  SettingsSwitch(
                    icon: Icons.notifications_active_rounded,
                    iconColor: AppColors.warning,
                    title: 'Budget alerts',
                    subtitle: 'Warn me as a budget nears its limit',
                    value: settings.budgetAlerts,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setBudgetAlerts(v),
                  ),
                  const SettingsTile(
                    icon: Icons.payments_rounded,
                    iconColor: AppColors.income,
                    title: 'Currency',
                    subtitle: 'Pakistani Rupee ($kCurrencySymbol)',
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SettingsGroup(
                title: 'Security',
                children: [
                  SettingsSwitch(
                    icon: Icons.lock_rounded,
                    iconColor: AppColors.brand,
                    title: 'App lock',
                    subtitle: security.lockEnabled
                        ? 'A PIN is required to open Kharcha'
                        : 'Protect Kharcha with a PIN',
                    value: security.lockEnabled,
                    onChanged: (v) => _toggleLock(context, ref, v),
                  ),
                  SettingsSwitch(
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.catTeal,
                    title: 'Unlock with biometrics',
                    subtitle: security.biometricAvailable
                        ? 'Use your fingerprint or face instead of the PIN'
                        : 'No biometrics enrolled on this device',
                    value: security.biometricEnabled,
                    onChanged:
                        security.lockEnabled && security.biometricAvailable
                        ? (v) => ref
                              .read(securityProvider.notifier)
                              .setBiometricEnabled(v)
                        : null,
                  ),
                  SettingsTile(
                    icon: Icons.password_rounded,
                    iconColor: AppColors.catBlue,
                    title: 'Change PIN',
                    onTap: security.lockEnabled
                        ? () =>
                              PinSetupSheet.show(context, requireCurrent: true)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SettingsGroup(
                title: 'Your data',
                children: [
                  SettingsTile(
                    icon: Icons.category_rounded,
                    iconColor: AppColors.catPink,
                    title: 'Categories',
                    onTap: () => CategoriesScreen.open(context),
                  ),
                  SettingsTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.catAmber,
                    title: 'Accounts',
                    onTap: () => AccountsScreen.open(context),
                  ),
                  SettingsTile(
                    icon: Icons.restart_alt_rounded,
                    iconColor: AppColors.catGreen,
                    title: 'Reset sample data',
                    subtitle: 'Rebuild the demo history from scratch',
                    onTap: () => _confirm(
                      context,
                      ref,
                      title: 'Reset sample data?',
                      body:
                          'Everything you have entered will be replaced by a fresh set of demo transactions.',
                      confirmLabel: 'Reset',
                      action: () => ref.read(actionsProvider).resetToSeed(),
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: AppColors.expense,
                    title: 'Delete all transactions',
                    subtitle: 'Keeps your categories, accounts and budgets',
                    destructive: true,
                    onTap: () => _confirm(
                      context,
                      ref,
                      title: 'Delete every transaction?',
                      body: 'This cannot be undone.',
                      confirmLabel: 'Delete',
                      action: () =>
                          ref.read(actionsProvider).clearTransactions(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              SettingsGroup(
                title: 'About',
                children: const [
                  SettingsTile(
                    icon: Icons.cloud_off_rounded,
                    iconColor: AppColors.catGreen,
                    title: 'Offline by design',
                    subtitle:
                        'No internet permission. Nothing leaves this device.',
                  ),
                  SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.inkFaint,
                    title: 'Kharcha',
                    subtitle: 'Version 1.0.0',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      await PinSetupSheet.show(context, requireCurrent: false);
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off app lock?'),
        content: const Text('Your PIN will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Turn off',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(securityProvider.notifier).disableLock();
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setUserName(name);
    }
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await action();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.balance,
    required this.onEdit,
  });

  final String name;
  final int balance;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'K'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                AmountText(
                  balance,
                  color: Colors.white.withValues(alpha: 0.85),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  fractionOpacity: 0.7,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
