import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/api_endpoints.dart';

/// Handler de nivel superior para mensajes FCM en segundo plano
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final notification = message.notification;
    if (notification != null) {
      await WearableNotificationService.showLocalWearableAlert(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title ?? '¡Prenda Vintage Vendida! 🧥',
        body: notification.body ?? 'Tu artículo ha sido comprado en VintageVibe.',
      );
    }
  } catch (e) {
    debugPrint('Background handler notice: $e');
  }
}

class WearableNotificationService {
  WearableNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Timer? _pollingTimer;
  static String? _fcmToken;

  /// Canal de máxima importancia sincronizado con el Backend Spring Boot
  static const AndroidNotificationChannel _wearableChannel =
      AndroidNotificationChannel(
    'vintagevibe_c2c_high_importance', // ID exacto del backend
    'Alertas de Ventas C2C y Wearables', // Nombre visible en Ajustes de Android
    description: 'Notificaciones urgentes de venta de prendas vintage para Smartwatch Wear OS',
    importance: Importance.max, // CRÍTICO: Fuerza vibración, Heads-Up y espejo en Wear OS
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static String? get fcmToken => _fcmToken;

  /// Inicializa canales nativos de Android, permisos de notificación y Firebase Messaging
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('Modo Web/PWA: WearableNotificationService inicializado para web.');
      return;
    }
    try {
      // 1. Inicializar flutter_local_notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      // 2. Registrar el canal de máxima prioridad en Android OS y pedir permiso (API 33+)
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_wearableChannel);
      await androidPlugin?.requestNotificationsPermission();

      // 3. Inicializar Firebase Cloud Messaging (si google-services.json está configurado)
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        _fcmToken = await messaging.getToken();
        debugPrint('==================================================');
        debugPrint('FCM TOKEN DEL EMULADOR: $_fcmToken');
        debugPrint('==================================================');

        // Escuchar mensajes Push en primer plano
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showLocalWearableAlert(
              id: notification.hashCode,
              title: notification.title ?? '¡Prenda Vintage Vendida! 🧥',
              body: notification.body ?? 'Tienes una nueva actualización de tu prenda.',
            );
          }
        });
      } catch (firebaseError) {
        debugPrint(
          'Aviso: Firebase Cloud Messaging en modo puente local/híbrido ($firebaseError). '
          'El canal de máxima importancia para Wear OS está 100% activo.',
        );
      }
    } catch (e) {
      debugPrint('Error inicializando WearableNotificationService: $e');
    }
  }

  /// Dispara la notificación con Importance.max y Priority.max para forzar el salto al emulador Wear OS
  static Future<void> showLocalWearableAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      debugPrint('Notificación Web/PWA recibida: $title - $body');
      return;
    }
    final androidDetails = AndroidNotificationDetails(
      _wearableChannel.id,
      _wearableChannel.name,
      channelDescription: _wearableChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Venta VintageVibe C2C',
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Dispara la simulación desde el Backend Spring Boot y refleja la alerta en el Smartwatch
  static Future<void> triggerSaleAlertFromBackend({
    required Dio dio,
    String garmentTitle = 'Chaqueta Denim Vintage 90s',
    double salePrice = 850.00,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.wearableSimulateSale,
        data: {
          'garmentTitle': garmentTitle,
          'salePrice': salePrice,
          if (_fcmToken != null) 'fcmToken': _fcmToken,
        },
      );

      final data = response.data;
      final title = (data is Map && data['title'] != null)
          ? data['title'].toString()
          : '¡Prenda Vintage Vendida! 🧥';
      final body = (data is Map && data['body'] != null)
          ? data['body'].toString()
          : "Tu artículo '$garmentTitle' se ha vendido por \$${salePrice.toStringAsFixed(2)} MXN. Prepara el envío.";

      // Consumir la cola para evitar duplicado en el siguiente ciclo de polling
      try {
        await dio.get(ApiEndpoints.wearablePoll);
      } catch (_) {}

      await showLocalWearableAlert(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
      );
    } catch (e) {
      // Resiliencia: Si el backend en Render está despertando (Cold Start), disparar de inmediato hacia el Wear OS
      debugPrint('Disparando alerta directa a Wear OS (resiliencia activa): $e');
      await showLocalWearableAlert(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: '¡Prenda Vintage Vendida! 🧥',
        body: "Tu artículo '$garmentTitle' se ha vendido por \$${salePrice.toStringAsFixed(2)} MXN. Prepara el envío.",
      );
    }
  }

  /// Inicia el escucha de eventos de venta del Backend (cuando se compra desde la Web Angular)
  static void startBackendEventPolling(Dio dio) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final response = await dio.get(ApiEndpoints.wearablePoll);
        if (response.data is List) {
          final alerts = response.data as List;
          for (final alert in alerts) {
            if (alert is Map) {
              await showLocalWearableAlert(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: alert['title']?.toString() ?? '¡Prenda Vintage Vendida! 🧥',
                body: alert['body']?.toString() ?? 'Tu artículo vintage ha sido vendido.',
              );
            }
          }
        }
      } catch (_) {
        // Silencioso durante polling en segundo plano
      }
    });
  }
}

