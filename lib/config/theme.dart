import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the "Glass Aurora" language shared with the web app —
/// translucent blurred surfaces over a dark (or, on mobile, soft light)
/// background, tied together by a fixed magenta→blue gradient accent.
/// Not part of [ColorScheme] because Material has no first-class concept of
/// a glass fill/border pair or a brand gradient; read via
/// `Theme.of(context).extension<GlassColors>()!`.
@immutable
class GlassColors extends ThemeExtension<GlassColors> {
  const GlassColors({
    required this.glass,
    required this.glassBorder,
    required this.glass2,
    required this.gradientStart,
    required this.gradientEnd,
    required this.muted,
    required this.muted2,
    required this.success,
  });

  final Color glass;
  final Color glassBorder;
  final Color glass2;
  final Color gradientStart;
  final Color gradientEnd;
  final Color muted;
  final Color muted2;
  final Color success;

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const dark = GlassColors(
    glass: Color(0x0EFFFFFF), // white @ 5.5%
    glassBorder: Color(0x1AFFFFFF), // white @ 10%
    glass2: Color(0x0BFFFFFF), // white @ 4.5%
    gradientStart: Color(0xFFC026D3),
    gradientEnd: Color(0xFF3B82F6),
    muted: Color(0xFFA9A6C4),
    muted2: Color(0xFF726F92),
    success: Color(0xFF34E0A1),
  );

  static const light = GlassColors(
    glass: Color(0xB3FFFFFF), // white @ 70%
    glassBorder: Color(0xFFE4E0F2),
    glass2: Color(0x80FFFFFF), // white @ 50%
    gradientStart: Color(0xFFC026D3),
    gradientEnd: Color(0xFF3B82F6),
    muted: Color(0xFF6B6785),
    muted2: Color(0xFF9490AC),
    success: Color(0xFF0E9F6E),
  );

  @override
  GlassColors copyWith({
    Color? glass,
    Color? glassBorder,
    Color? glass2,
    Color? gradientStart,
    Color? gradientEnd,
    Color? muted,
    Color? muted2,
    Color? success,
  }) {
    return GlassColors(
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      glass2: glass2 ?? this.glass2,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      muted: muted ?? this.muted,
      muted2: muted2 ?? this.muted2,
      success: success ?? this.success,
    );
  }

  @override
  GlassColors lerp(ThemeExtension<GlassColors>? other, double t) {
    if (other is! GlassColors) return this;
    return GlassColors(
      glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glass2: Color.lerp(glass2, other.glass2, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      muted2: Color.lerp(muted2, other.muted2, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

abstract final class AppTheme {
  /// Legacy alias kept for the logo/splash gradient — same stops as
  /// [GlassColors.accentGradient].
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC026D3), Color(0xFF3B82F6)],
  );

  static TextStyle monoStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static ThemeData get light {
    const g = GlassColors.light;
    const background = Color(0xFFF5F3FB);
    final cs = const ColorScheme.light().copyWith(
      primary: g.gradientStart,
      onPrimary: Colors.white,
      secondary: g.gradientEnd,
      onSecondary: Colors.white,
      surface: background,
      onSurface: const Color(0xFF1B1730),
      onSurfaceVariant: g.muted,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      outline: g.glassBorder,
      surfaceContainerHigh: g.glass2,
    );
    return _build(cs: cs, glass: g, background: background);
  }

  static ThemeData get dark {
    const g = GlassColors.dark;
    const background = Color(0xFF0A0917);
    final cs = const ColorScheme.dark().copyWith(
      primary: g.gradientStart,
      onPrimary: Colors.white,
      secondary: g.gradientEnd,
      onSecondary: Colors.white,
      surface: background,
      onSurface: const Color(0xFFF1EEFC),
      onSurfaceVariant: g.muted,
      error: const Color(0xFFF87171),
      onError: Colors.white,
      outline: g.glassBorder,
      surfaceContainerHigh: g.glass2,
    );
    return _build(cs: cs, glass: g, background: background);
  }

  static ThemeData _build({
    required ColorScheme cs,
    required GlassColors glass,
    required Color background,
  }) {
    final isDark = cs.brightness == Brightness.dark;
    final displayFont = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: cs.brightness).textTheme,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    final glassShape = RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      side: BorderSide(color: glass.glassBorder),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      extensions: [glass],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: displayFont.headlineLarge,
        headlineMedium: displayFont.headlineMedium,
        headlineSmall: displayFont.headlineSmall,
        titleLarge: displayFont.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: displayFont.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: cs.onSurface,
        iconTheme: IconThemeData(color: cs.onSurface),
        titleTextStyle: displayFont.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: glass.glass,
        shape: glassShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF16142B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF16142B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF211E3D) : cs.onSurface,
        contentTextStyle: TextStyle(
          color: isDark ? cs.onSurface : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: glass.glassBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: glass.glass2,
        side: BorderSide(color: glass.glassBorder),
        labelStyle: TextStyle(color: cs.onSurface, fontSize: 12),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.glass2,
        labelStyle: TextStyle(color: glass.muted),
        hintStyle: TextStyle(color: glass.muted2),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: glass.gradientEnd, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: glass.gradientStart,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: glass.glassBorder),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(glass.glass2),
        side: WidgetStatePropertyAll(BorderSide(color: glass.glassBorder)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        textStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 15)),
        hintStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 15, color: glass.muted2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: glass.gradientStart,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
