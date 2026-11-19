import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/wearable_notification_service.dart';
import '../../../../shared/widgets/ios_pressable.dart';

class _WatchAlert {
  final int id;
  final String title;
  final String body;
  final DateTime receivedAt;
  bool confirmed;

  _WatchAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.confirmed = false,
  });
}

/// Vista Smartwatch Companion en tiempo real (/watch).
/// Escucha eventos de venta reales del backend Spring Boot (/api/v1/notifications/wearable/poll)
/// para demostrar la integración wearable en cualquier iPhone, navegador o segundo dispositivo.
class WatchCompanionScreen extends ConsumerStatefulWidget {
  const WatchCompanionScreen({super.key});

  @override
  ConsumerState<WatchCompanionScreen> createState() => _WatchCompanionScreenState();
}

class _WatchCompanionScreenState extends ConsumerState<WatchCompanionScreen> {
  static const Color _watchBg = Color(0xFF0B0B0C);
  static const Color _watchSurface = Color(0xFF161618);
  static const Color _watchBorder = Color(0xFF262629);
  static const Color _watchText = Color(0xFFF5F5F7);

  late Timer _clockTimer;
  Timer? _fastPollTimer;
  StreamSubscription<Map<String, dynamic>>? _alertSub;

  DateTime _now = DateTime.now();
  _WatchAlert? _activeAlert;
  final List<_WatchAlert> _history = [];
  bool _isSendingDemo = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // Suscribirse al stream de alertas en tiempo real
    _alertSub = WearableNotificationService.alertStream.listen((payload) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final incoming = _WatchAlert(
        id: (payload['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        title: (payload['title']?.toString() ?? 'Prenda Vintage Vendida').replaceAll('🧥', '').trim(),
        body: payload['body']?.toString() ?? 'Tu prenda ha sido vendida en VintageVibe.',
        receivedAt: DateTime.now(),
      );
      setState(() {
        _activeAlert = incoming;
        _history.insert(0, incoming);
      });
    });

    // Polling rápido cada 3 segundos mientras la carátula del reloj está abierta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dio = ref.read(dioProvider);
      WearableNotificationService.pollBackendOnce(dio);
      _fastPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        WearableNotificationService.pollBackendOnce(dio);
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _fastPollTimer?.cancel();
    _alertSub?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String get _formattedTime => '${_twoDigits(_now.hour)}:${_twoDigits(_now.minute)}';
  String get _formattedSeconds => _twoDigits(_now.second);

  Future<void> _sendTestSale() async {
    setState(() => _isSendingDemo = true);
    try {
      final dio = ref.read(dioProvider);
      await WearableNotificationService.triggerSaleAlertFromBackend(
        dio: dio,
        garmentTitle: 'Chaqueta Denim Vintage 90s',
        salePrice: 850.00,
      );
    } finally {
      if (mounted) setState(() => _isSendingDemo = false);
    }
  }

  void _confirmActiveAlert() {
    if (_activeAlert == null) return;
    HapticFeedback.lightImpact();
    setState(() {
      _activeAlert!.confirmed = true;
      _activeAlert = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _watchBg,
      appBar: AppBar(
        backgroundColor: _watchBg,
        foregroundColor: _watchText,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _watchBorder, width: 0.5)),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, size: 20, color: _watchText),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Wear OS Companion',
          style: AppTypography.titleLarge.copyWith(color: _watchText),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          children: [
            // Estado de conexión con Render API
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _watchSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _watchBorder, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Escuchando ventas en vivo · Render API',
                    style: AppTypography.labelMedium.copyWith(color: _watchText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Carátula circular del Smartwatch (300x300)
            Center(
              child: Container(
                width: 300,
                height: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _watchSurface,
                  border: Border.all(color: _watchBorder, width: 4),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _watchBg,
                    border: Border.all(
                      color: _activeAlert != null ? const Color(0xFF4CAF50) : _watchBorder,
                      width: _activeAlert != null ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _activeAlert != null
                        ? _buildWatchAlertFace(_activeAlert!)
                        : _buildWatchClockFace(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Controles de demostración
            SizedBox(
              width: double.infinity,
              child: IosPressable(
                onTap: _isSendingDemo ? null : _sendTestSale,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _watchText,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _isSendingDemo
                      ? const CupertinoActivityIndicator(radius: 9, color: _watchBg)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(CupertinoIcons.bell_fill, size: 16, color: _watchBg),
                            const SizedBox(width: 8),
                            Text(
                              'Simular venta en tiempo real',
                              style: AppTypography.button.copyWith(color: _watchBg),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'También puedes comprar una prenda desde otro teléfono o desde la Web y la alerta aparecerá automáticamente aquí en menos de 3 segundos.',
              style: AppTypography.caption.copyWith(color: AppColors.gray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Historial de alertas recibidas en el reloj
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ALERTAS RECIBIDAS (${_history.length})',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gray,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _watchSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _watchBorder, width: 0.8),
                ),
                child: Text(
                  'Sin ventas recientes. Esperando eventos del servidor...',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._history.map((item) {
                final hhmm =
                    '${_twoDigits(item.receivedAt.hour)}:${_twoDigits(item.receivedAt.minute)}:${_twoDigits(item.receivedAt.second)}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _watchSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _watchBorder, width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.confirmed
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.bell_fill,
                        size: 18,
                        color: item.confirmed ? const Color(0xFF4CAF50) : _watchText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.titleSmall.copyWith(color: _watchText),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  hhmm,
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.gray),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.gray),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.confirmed ? 'Envío confirmado desde reloj' : 'Notificación entregada',
                              style: AppTypography.labelSmall.copyWith(
                                color: item.confirmed ? const Color(0xFF4CAF50) : AppColors.gray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchClockFace() {
    return Padding(
      key: const ValueKey('clock-face'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'VINTAGEVIBE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.gray,
              letterSpacing: 2.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formattedTime,
                style: AppTypography.displayLarge.copyWith(
                  color: _watchText,
                  fontSize: 48,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formattedSeconds,
                style: AppTypography.titleMedium.copyWith(color: AppColors.gray),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.antenna_radiowaves_left_right,
                  size: 14, color: Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              Text(
                'Sin ventas pendientes',
                style: AppTypography.labelSmall.copyWith(color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAlertFace(_WatchAlert alert) {
    return Padding(
      key: ValueKey('alert-${alert.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.bag_fill, size: 22, color: Color(0xFF4CAF50)),
          const SizedBox(height: 8),
          Text(
            alert.title,
            style: AppTypography.titleSmall.copyWith(color: _watchText, fontSize: 13),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            alert.body,
            style: AppTypography.labelSmall.copyWith(color: const Color(0xFFB8B8BE), fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IosPressable(
                onTap: () => setState(() => _activeAlert = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _watchSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _watchBorder),
                  ),
                  child: Text(
                    'Cerrar',
                    style: AppTypography.labelSmall.copyWith(color: _watchText),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IosPressable(
                onTap: _confirmActiveAlert,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Confirmar',
                    style: AppTypography.labelSmall.copyWith(
                      color: _watchBg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
