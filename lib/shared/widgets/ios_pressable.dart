import 'package:flutter/material.dart';

/// Feedback táctil sutil estilo iPhone: escala 0.98 y ligera opacidad en 150ms,
/// sin efectos ripple agresivos de Material.
class IosPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double pressedOpacity;

  const IosPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.98,
    this.pressedOpacity = 0.85,
  });

  @override
  State<IosPressable> createState() => _IosPressableState();
}

class _IosPressableState extends State<IosPressable> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? widget.pressedOpacity : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
