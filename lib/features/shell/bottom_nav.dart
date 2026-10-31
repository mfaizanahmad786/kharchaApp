import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Height of the nav sheet, excluding the device's bottom inset.
const double kNavBarHeight = 74;

/// Vertical space a scrolling screen should leave so its last row clears the
/// floating nav bar and the FAB.
const double kNavBarScrollPadding = 118;

class NavDestination {
  const NavDestination(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const navDestinations = <NavDestination>[
  NavDestination('Home', Icons.home_outlined, Icons.home_rounded),
  NavDestination('Report', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
  NavDestination('Plan', Icons.layers_outlined, Icons.layers_rounded),
  NavDestination('Settings', Icons.settings_outlined, Icons.settings_rounded),
];

/// The floating white nav sheet with the purple add-button punched through it.
class KharchaBottomNav extends StatelessWidget {
  const KharchaBottomNav({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: kNavBarHeight + bottomInset + 22,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: kNavBarHeight + bottomInset,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: AppColors.navShadow,
              ),
              child: Row(
                children: [
                  _item(0),
                  _item(1),
                  const SizedBox(width: 76),
                  _item(2),
                  _item(3),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: kNavBarHeight + bottomInset - 44,
            child: _AddButton(onTap: onAdd),
          ),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final d = navDestinations[i];
    final selected = i == index;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.0 : 0.94,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                selected ? d.activeIcon : d.icon,
                size: 24,
                color: selected ? AppColors.ink : AppColors.inkFaint,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.inkFaint,
              ),
              child: Text(d.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.purple.withValues(alpha: 0.16),
          ),
          child: Center(
            child: Material(
              color: AppColors.purple,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Ink(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.42),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
