import 'dart:ui';
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

    return Scaffold(
      backgroundColor: AppColors.light,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Contenido a pantalla completa para que pase detrás del cristal translúcido
          child,

          // Barra de navegación flotante estilo iOS Liquid Glass pegada casi al borde inferior
          Positioned(
            left: 14,
            right: 14,
            bottom: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xE0161618),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      _LiquidGlassNavItem(
                        icon: CupertinoIcons.compass,
                        activeIcon: CupertinoIcons.compass_fill,
                        label: 'Explorar',
                        isSelected: currentIndex == 0,
                        onTap: () => context.goNamed(AppRoutes.home),
                      ),
                      _LiquidGlassNavItem(
                        icon: CupertinoIcons.plus_square,
                        activeIcon: CupertinoIcons.plus_square_fill,
                        label: 'Publicar',
                        isSelected: currentIndex == 1,
                        onTap: () => context.goNamed(AppRoutes.publish),
                      ),
                      _LiquidGlassNavItem(
                        icon: CupertinoIcons.bag,
                        activeIcon: CupertinoIcons.bag_fill,
                        label: 'Carrito',
                        isSelected: currentIndex == 2,
                        onTap: () => context.goNamed(AppRoutes.cart),
                      ),
                      _LiquidGlassNavItem(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fgColor =
        isSelected ? Colors.white : Colors.white.withValues(alpha: 0.72);

    return Expanded(
      child: IosPressable(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 21,
                color: fgColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: fgColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 10.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
