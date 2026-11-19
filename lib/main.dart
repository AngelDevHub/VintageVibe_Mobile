import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/services/wearable_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Inicializar servicio de notificaciones de alta prioridad y puente Wear OS (Práctica 2)
  await WearableNotificationService.initialize();
  
  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(
      child: VintageVibeApp(),
    ),
  );
}

class VintageVibeApp extends ConsumerStatefulWidget {
  const VintageVibeApp({super.key});

  @override
  ConsumerState<VintageVibeApp> createState() => _VintageVibeAppState();
}

class _VintageVibeAppState extends ConsumerState<VintageVibeApp> {
  @override
  void initState() {
    super.initState();
    // Iniciar escucha de eventos de venta C2C del backend hacia el Smartwatch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dio = ref.read(dioProvider);
      WearableNotificationService.startBackendEventPolling(dio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'VintageVibe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
