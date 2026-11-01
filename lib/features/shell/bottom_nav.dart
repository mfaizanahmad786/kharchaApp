import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';

/// Height of the nav sheet, excluding the device's bottom inset.
const double kNavBarHeight = 76;

/// Vertical space a scrolling screen should leave so its last row clears the
/// floating nav bar and the FAB.
const double kNavBarScrollPadding = 124;

class NavDestination {
  const NavDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Filled icons throughout: the reference never uses outlined glyphs here.
const navDestinations = <NavDestination>[
  NavDestination('Home', Icons.home_rounded),
  NavDestination('Report', Icons.bar_chart_rounded),
  NavDestination('Plan', Icons.layers_rounded),
  NavDestination('Settings', Icons.settings_rounded),
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
    final p = context.palette;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: kNavBarHeight + bottomInset + 26,
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
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: AppRadii.navTop,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _item(p, 0),
                  _item(p, 1),
                  const SizedBox(width: 80),
                  _item(p, 2),
                  _item(p, 3),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: kNavBarHeight + bottomInset - 46,
            child: _AddButton(onTap: onAdd),
          ),
        ],
      ),
    );
  }

  Widget _item(AppPalette p, int i) {
    final d = navDestinations[i];
    final selected = i == index;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(i),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(d.icon, size: 25, color: selected ? p.ink : p.navInactive),
            const SizedBox(height: 4),
            Text(
              d.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? p.ink : p.navInactive,
              ),
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
      width: 92,
      height: 92,
      child: Center(
        child: Container(
          // The faint halo ring around the button.
          width: AppSizes.fab + 16,
          height: AppSizes.fab + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brand.withValues(alpha: 0.14),
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // White on brandLight is only 2.54:1; this pair holds 3.77:1.
                  colors: [AppColors.brandDark, AppColors.brand],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: const SizedBox(
                    width: AppSizes.fab,
                    height: AppSizes.fab,
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
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
