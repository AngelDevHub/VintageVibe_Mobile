import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 130.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.surfaceSoft,
              child: Text(
                (user != null && user.firstName.isNotEmpty)
                    ? user.firstName.substring(0, 1).toUpperCase()
                    : 'V',
                style: AppTypography.displayMedium.copyWith(color: AppColors.dark),
              ),
            ),
            const SizedBox(height: 16),
            
            // User info
            Text(
              '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
              style: AppTypography.displaySmall.copyWith(color: AppColors.dark),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'usuario@vintagevibe.com',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.gray),
            ),
            const SizedBox(height: 32),

            // Options
            _buildProfileOption(
              icon: CupertinoIcons.heart,
              title: 'Mis Favoritos',
              onTap: () => context.push('/favorites'),
            ),
            _buildProfileOption(
              icon: CupertinoIcons.cube_box,
              title: 'Mis Pedidos',
              onTap: () => context.push('/orders'),
            ),
            _buildProfileOption(
              icon: CupertinoIcons.tag,
              title: 'Mis Publicaciones C2C',
              onTap: () => context.push('/my-listings'),
            ),
            _buildProfileOption(
              icon: CupertinoIcons.bell,
              title: 'Wear OS Companion (Reloj en vivo)',
              onTap: () => context.push('/watch'),
            ),
            _buildProfileOption(
              icon: CupertinoIcons.settings,
              title: 'Configuración',
              onTap: () => context.push('/settings'),
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'Cerrar Sesión',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayLight.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(color: AppColors.darkSecondary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grayLight),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
