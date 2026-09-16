import 'package:flutter/material.dart';
import 'package:mediqux_mobile/config/theme.dart';

/// Slowly-breathing blurred gradient blobs behind the login/setup screens —
/// mirrors the web app's fixed "aurora" radial-gradient backdrop. Respects
/// the platform's reduced-motion setting by freezing on the first frame
/// instead of animating.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassColors>()!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return _AuroraBlobs(t: 0.5, glass: glass);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _AuroraBlobs(
        t: Curves.easeInOut.transform(_controller.value),
        glass: glass,
      ),
    );
  }
}

class _AuroraBlobs extends StatelessWidget {
  const _AuroraBlobs({required this.t, required this.glass});

  final double t;
  final GlassColors glass;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            _blob(
              alignment: Alignment(-1.1 + t * 0.3, -1.2),
              color: glass.gradientStart,
            ),
            _blob(
              alignment: Alignment(1.2, -1.0 - t * 0.2),
              color: glass.gradientEnd,
            ),
            _blob(
              alignment: Alignment(1.1 - t * 0.2, 1.2),
              color: glass.gradientStart,
            ),
            _blob(
              alignment: Alignment(-1.2, 1.1 + t * 0.2),
              color: glass.gradientEnd,
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 320,
        height: 320,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
