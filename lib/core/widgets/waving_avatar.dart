import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavingAvatar extends StatefulWidget {
  final VoidCallback onTap;
  final double radius;

  const WavingAvatar({
    super.key,
    required this.onTap,
    this.radius = 20,
  });

  @override
  State<WavingAvatar> createState() => _WavingAvatarState();
}

class _WavingAvatarState extends State<WavingAvatar> with TickerProviderStateMixin {
  late AnimationController _turnController;
  late Animation<double> _turnAnimation;

  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();

    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _turnAnimation = Tween<double>(begin: math.pi, end: 0).animate(
      CurvedAnimation(parent: _turnController, curve: Curves.easeOutBack),
    );

    // Start animation shortly after mounting
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _playAnimation();
    });
  }

  Future<void> _playAnimation() async {
    if (_hasStarted) return;
    _hasStarted = true;

    // 1. Turn around
    await _turnController.forward();
  }

  @override
  void dispose() {
    _turnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        // If they tap it while turned away, force turn
        if (_turnController.isDismissed) {
          _turnController.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _turnAnimation,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateY(_turnAnimation.value),
            child: child,
          );
        },
        child: CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.grey.shade300,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // The person silhouette
              Icon(
                Icons.person,
                color: Colors.white,
                size: widget.radius * 1.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
