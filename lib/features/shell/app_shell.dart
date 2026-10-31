import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../plan/plan_screen.dart';
import '../report/report_screen.dart';
import '../settings/settings_screen.dart';
import '../transaction/add_transaction_sheet.dart';
import 'bottom_nav.dart';

/// Lets any descendant jump tabs — used by "Details >" on Home, for instance.
class ShellNavigator extends InheritedWidget {
  const ShellNavigator({super.key, required this.go, required super.child});

  final void Function(int index) go;

  static ShellNavigator? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellNavigator>();

  @override
  bool updateShouldNotify(ShellNavigator old) => false;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void _go(int i) {
    if (i == _index) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  Future<bool> _popCurrentTab() async {
    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ShellNavigator(
      go: _go,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _popCurrentTab() && context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffold,
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [
              _TabHost(navKey: _navKeys[0], child: const HomeScreen()),
              _TabHost(navKey: _navKeys[1], child: const ReportScreen()),
              _TabHost(navKey: _navKeys[2], child: const PlanScreen()),
              _TabHost(navKey: _navKeys[3], child: const SettingsScreen()),
            ],
          ),
          bottomNavigationBar: KharchaBottomNav(
            index: _index,
            onSelect: _go,
            onAdd: () => AddTransactionSheet.show(context),
          ),
        ),
      ),
    );
  }
}

/// Each tab keeps its own navigation stack so pushing a detail screen does not
/// cover the bottom bar of the other tabs.
class _TabHost extends StatelessWidget {
  const _TabHost({required this.navKey, required this.child});

  final GlobalKey<NavigatorState> navKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navKey,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => child,
      ),
    );
  }
}
