import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../core/storage/local_catalog_database.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../../catalog/presentation/providers/favorites_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _notifKey = 'vv_pref_notifications';
  static const _offlineKey = 'vv_pref_offline_cache';

  bool _notificationsEnabled = true;
  bool _offlineCacheEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final notif = await SecureStorage.readValue(_notifKey);
    final offline = await SecureStorage.readValue(_offlineKey);
    if (!mounted) return;
    setState(() {
      if (notif != null) _notificationsEnabled = notif == 'true';
      if (offline != null) _offlineCacheEnabled = offline == 'true';
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await SecureStorage.writeValue(_notifKey, value.toString());
  }

  Future<void> _toggleOfflineCache(bool value) async {
    setState(() => _offlineCacheEnabled = value);
    await SecureStorage.writeValue(_offlineKey, value.toString());
  }

  Future<void> _clearCache() async {
    await LocalCatalogDatabase.instance.clearAll();
    ref.invalidate(productsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caché local limpiada correctamente')),
    );
  }

  Future<void> _clearFavorites() async {
    await ref.read(favoritesProvider.notifier).clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista de favoritos vaciada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final favCount = ref.watch(favoritesProvider).length;

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, size: 20, color: AppColors.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionLabel('PREFERENCIAS'),
          _GroupedCard(
            children: [
              _SwitchTile(
                icon: CupertinoIcons.bell,
                title: 'Alertas de ventas C2C y Wear OS',
                subtitle: 'Recibe avisos cuando compren tus prendas',
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
              const Divider(),
              _SwitchTile(
                icon: CupertinoIcons.cloud_download,
                title: 'Caché offline del catálogo',
                subtitle: 'Guarda prendas localmente en SQLite',
                value: _offlineCacheEnabled,
                onChanged: _toggleOfflineCache,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('ALMACENAMIENTO'),
          _GroupedCard(
            children: [
              _ActionTile(
                icon: CupertinoIcons.trash,
                title: 'Limpiar caché offline',
                subtitle: 'Refresca el catálogo desde el servidor',
                onTap: _clearCache,
              ),
              const Divider(),
              _ActionTile(
                icon: CupertinoIcons.heart_slash,
                title: 'Vaciar favoritos ($favCount)',
                subtitle: 'Elimina todas tus prendas guardadas',
                onTap: favCount == 0 ? null : _clearFavorites,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel('CUENTA Y APLICACIÓN'),
          _GroupedCard(
            children: [
              _InfoTile(
                icon: CupertinoIcons.person,
                title: 'Cuenta activa',
                value: user?.email ?? 'Sin sesión',
              ),
              const Divider(),
              _InfoTile(
                icon: CupertinoIcons.shield,
                title: 'Rol',
                value: user?.role ?? 'ROLE_USER',
              ),
              const Divider(),
              _InfoTile(
                icon: CupertinoIcons.globe,
                title: 'Servidor API',
                value: AppConfig.apiBaseUrl.replaceFirst('https://', ''),
              ),
              const Divider(),
              const _InfoTile(
                icon: CupertinoIcons.info,
                title: 'Versión',
                value: '1.0.0 · Editorial iOS',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          letterSpacing: 0.9,
          fontWeight: FontWeight.w600,
          color: AppColors.gray,
        ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.dark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.dark,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: enabled ? AppColors.dark : AppColors.gray),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: enabled ? AppColors.dark : AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.gray),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.dark),
          const SizedBox(width: 12),
          Text(title, style: AppTypography.titleSmall),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
