import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/theme/app_colors.dart';
import '../../core/config/theme/app_typography.dart';
import '../../core/router/app_router.dart';
import 'ios_pressable.dart';

class VVShell extends StatelessWidget {
  final Widget child;

  const VVShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;

    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/publish')) currentIndex = 1;
    if (location.startsWith('/cart')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset > 16 ? bottomInset - 14 : (bottomInset > 0 ? bottomInset : 8.0);

    return Scaffold(
      backgroundColor: AppColors.light,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.light,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              _EditorialNavItem(
                icon: CupertinoIcons.compass,
                activeIcon: CupertinoIcons.compass_fill,
                label: 'Explorar',
                isSelected: currentIndex == 0,
                onTap: () => context.goNamed(AppRoutes.home),
              ),
              _EditorialNavItem(
                icon: CupertinoIcons.plus_square,
                activeIcon: CupertinoIcons.plus_square_fill,
                label: 'Publicar',
                isSelected: currentIndex == 1,
                onTap: () => context.goNamed(AppRoutes.publish),
              ),
              _EditorialNavItem(
                icon: CupertinoIcons.bag,
                activeIcon: CupertinoIcons.bag_fill,
                label: 'Carrito',
                isSelected: currentIndex == 2,
                onTap: () => context.goNamed(AppRoutes.cart),
              ),
              _EditorialNavItem(
                icon: CupertinoIcons.person,
                activeIcon: CupertinoIcons.person_fill,
                label: 'Perfil',
                isSelected: currentIndex == 3,
                onTap: () => context.goNamed(AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditorialNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.dark : AppColors.gray;

    return Expanded(
      child: IosPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
