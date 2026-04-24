import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../router/shell_scaffold.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'waving_avatar.dart';
import 'dart:math' as math;

class GlobalHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GlobalHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_rounded; // Afternoon sun
    return Icons.nightlight_round;
  }

  String _getDate() {
    return DateFormat('EEE, MMM d').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD4E9E2),
        border: Border(bottom: BorderSide(color: const Color(0xFF006241).withValues(alpha: 0.05), width: 1)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 48,
        left: 24,
        right: 24,
        bottom: 32,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Transform.rotate(
              angle: 0.3,
              child: Icon(
                LucideIcons.chefHat,
                size: 200,
                color: const Color(0xFF0D5C3E).withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      WavingAvatar(
                        onTap: () => shellScaffoldKey.currentState?.openDrawer(),
                        radius: 24,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        children: [
                          Text(
                            _getGreeting(),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _AnimatedGreetingIcon(icon: _getGreetingIcon()),
                        ],
                      ),
                          Text(
                            _getDate(),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF006241),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedGreetingIcon extends StatefulWidget {
  final IconData icon;
  const _AnimatedGreetingIcon({required this.icon});

  @override
  State<_AnimatedGreetingIcon> createState() => _AnimatedGreetingIconState();
}

class _AnimatedGreetingIconState extends State<_AnimatedGreetingIcon> with SingleTickerProviderStateMixin {
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
      if (mounted && !_hasStarted) {
        _hasStarted = true;
        _turnController.forward();
      }
    });
  }

  @override
  void dispose() {
    _turnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = const Color(0xFFF5A623); // Bright golden yellow

    return AnimatedBuilder(
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
      child: Icon(widget.icon, size: 16, color: iconColor),
    );
  }
}
