import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MediquxLogo extends StatelessWidget {
  const MediquxLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D8EA0), Color(0xFF003640)],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6E7C).withValues(alpha: 0.45),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.22),
        child: SvgPicture.asset(
          'assets/icons/heart_pulse.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
