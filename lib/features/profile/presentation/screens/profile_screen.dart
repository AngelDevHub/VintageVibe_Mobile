import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/wearable_notification_service.dart';

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                (user != null && user.firstName.isNotEmpty)
                    ? user.firstName.substring(0, 1).toUpperCase()
                    : 'V',
                style: AppTypography.displayMedium.copyWith(color: AppColors.white),
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
              icon: Icons.favorite_border,
              title: 'Mis Favoritos',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.local_shipping_outlined,
              title: 'Mis Pedidos',
              onTap: () => context.push('/orders'),
            ),
            _buildProfileOption(
              icon: Icons.store_outlined,
              title: 'Mis Publicaciones C2C',
              onTap: () => context.push('/my-listings'),
            ),
            _buildProfileOption(
              icon: Icons.watch_outlined,
              title: 'Práctica 2: Probar Alerta Wearable',
              onTap: () => _showWearableDemoSheet(context, ref),
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: 'Configuración',
              onTap: () {},
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

  void _showWearableDemoSheet(BuildContext context, WidgetRef ref) {
    final dio = ref.read(dioProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.watch, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Práctica 2: Conexión Externa (Wear OS)',
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Simula la compra de tu prenda vintage desde el backend (Spring Boot) '
                'y envía una notificación Push de máxima prioridad (Importance.max) que '
                'hace mirroring hacia el emulador de Wear OS.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⏱️ ¡Bloquea o sal de la pantalla del teléfono ahora! '
                        'Enviando alerta al Smartwatch en 5 segundos...',
                      ),
                      backgroundColor: AppColors.primaryDark,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  Timer(const Duration(seconds: 5), () {
                    WearableNotificationService.triggerSaleAlertFromBackend(
                      dio: dio,
                      garmentTitle: 'Chaqueta Denim Vintage 90s',
                      salePrice: 850.00,
                    );
                  });
                },
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Disparar en 5 seg (Para bloquear teléfono)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  WearableNotificationService.triggerSaleAlertFromBackend(
                    dio: dio,
                    garmentTitle: 'Chaqueta Denim Vintage 90s',
                    salePrice: 850.00,
                  );
                },
                icon: const Icon(Icons.bolt),
                label: const Text('Disparo Inmediato'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayLight.withOpacity(0.5)),
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
