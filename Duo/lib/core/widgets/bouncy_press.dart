import 'package:flutter/material.dart';

/// A premium, tactile micro-interaction wrapper.
/// Smoothly scales down on tap and springs back with optional haptic semantics.
class BouncyPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;
  final String? semanticsLabel;
  final String? semanticsHint;
  final bool enabled;
  final HitTestBehavior behavior;

  const BouncyPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.semanticsLabel,
    this.semanticsHint,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BouncyPress> createState() => _BouncyPressState();
}

class _BouncyPressState extends State<BouncyPress> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!widget.enabled || widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = AnimatedScale(
      scale: _isPressed ? widget.scaleFactor : 1.0,
      duration: widget.duration,
      curve: Curves.easeInOutCubic,
      child: widget.child,
    );

    if (widget.semanticsLabel != null) {
      result = Semantics(
        label: widget.semanticsLabel,
        hint: widget.semanticsHint,
        button: true,
        enabled: widget.enabled,
        child: result,
      );
    }

    if (widget.onTap == null && widget.onLongPress == null) {
      return result;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: result,
    );
  }
}
