// =============================================================================
// app_theme.dart — Bound2Game Flutter (Android)
// Fuente: InterfazdeusuarioBound2game - CORRECTO
//   ├── src/styles/theme.css  → colores light & dark
//   └── src/styles/fonts.css  → tipografía Inter
// La app usa EXCLUSIVAMENTE el modo oscuro (.dark del CSS).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORES — extraídos de theme.css (.dark block) y gameData.ts configs
// ─────────────────────────────────────────────────────────────────────────────

/// Paleta de colores del sistema de diseño Bound2Game.
abstract final class AppColors {
  // Fondos
  /// --background: oklch(0.145 0 0) ≈ #1A1A1A
  static const Color background      = Color(0xFF1A1A1A);
  /// --card: oklch(0.145 0 0)
  static const Color card            = Color(0xFF1A1A1A);
  /// --sidebar: oklch(0.205 0 0) ≈ #303030
  static const Color sidebar         = Color(0xFF303030);
  /// --secondary/muted/accent: oklch(0.269 0 0) ≈ #3E3E3E
  static const Color surface         = Color(0xFF3E3E3E);
  /// Input background (dark equivalent of #f3f3f5)
  static const Color inputBackground = Color(0xFF2C2C2E);

  // Primer plano
  /// --foreground: oklch(0.985 0 0) ≈ #F7F7F7
  static const Color foreground      = Color(0xFFF7F7F7);
  /// --muted-foreground: oklch(0.708 0 0) ≈ #8E8E8E
  static const Color mutedForeground = Color(0xFF8E8E8E);

  // Primario (dark: blanco)
  /// --primary: oklch(0.985 0 0) ≈ #F7F7F7
  static const Color primary            = Color(0xFFF7F7F7);
  /// --primary-foreground: oklch(0.205 0 0) ≈ #303030
  static const Color primaryForeground  = Color(0xFF303030);

  // Sidebar primary (accent azul eléctrico)
  /// --sidebar-primary: oklch(0.488 0.243 264.376) ≈ #4A6CF7
  static const Color sidebarPrimary            = Color(0xFF4A6CF7);
  static const Color sidebarPrimaryForeground  = Color(0xFFF7F7F7);

  // Destructivo
  /// --destructive: oklch(0.396 0.141 25.723) ≈ #8B2020
  static const Color destructive           = Color(0xFF8B2020);
  /// --destructive-foreground: oklch(0.637 0.237 25.331) ≈ #FF6B6B
  static const Color destructiveForeground = Color(0xFFFF6B6B);

  // Bordes
  /// --border: oklch(0.269 0 0) ≈ #3E3E3E
  static const Color border = Color(0xFF3E3E3E);
  /// --ring: oklch(0.439 0 0) ≈ #5C5C5C
  static const Color ring   = Color(0xFF5C5C5C);

  // ── Reputación (REPUTATION_CONFIG en gameData.ts) ─────────────────────────
  static const Color repLegendary = Color(0xFFFFD700);
  static const Color repExemplar  = Color(0xFF4AF626);
  static const Color repPositive  = Color(0xFF00E5FF);
  static const Color repNeutral   = Color(0xFF888888);
  static const Color repNegative  = Color(0xFFFF4040);

  static Color repLegendaryBg = const Color(0xFFFFD700).withOpacity(0.15);
  static Color repExemplarBg  = const Color(0xFF4AF626).withOpacity(0.15);
  static Color repPositiveBg  = const Color(0xFF00E5FF).withOpacity(0.15);
  static Color repNeutralBg   = const Color(0xFF888888).withOpacity(0.15);
  static Color repNegativeBg  = const Color(0xFFFF4040).withOpacity(0.15);

  // ── Plataformas (PLATFORM_CONFIG en gameData.ts) ──────────────────────────
  static const Color platformSteam = Color(0xFF1B9ED9);
  static const Color platformEpic  = Color(0xFFFFFFFF);
  static const Color platformIg    = Color(0xFFFF6B00);
  static const Color platformB2g   = Color(0xFF9B59B6);

  // ── Requisitos de PC (PC_REQ_CONFIG en gameData.ts) ───────────────────────
  static const Color pcReqGreen  = Color(0xFF4AF626);
  static const Color pcReqYellow = Color(0xFFFFB800);
  static const Color pcReqRed    = Color(0xFFFF4040);
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIO DE BORDES
// --radius: 0.625rem = 10px → sm=6, md=8, lg=10, xl=14
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 10.0;
  static const double xl   = 14.0;
  static const double full = 999.0;

  static BorderRadius get roundedSm   => BorderRadius.circular(sm);
  static BorderRadius get roundedMd   => BorderRadius.circular(md);
  static BorderRadius get roundedLg   => BorderRadius.circular(lg);
  static BorderRadius get roundedXl   => BorderRadius.circular(xl);
  static BorderRadius get roundedFull => BorderRadius.circular(full);
}

// ─────────────────────────────────────────────────────────────────────────────
// ESPACIADO — escala de 4px (equivalente a Tailwind p-1 = 4px)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 32.0;
  static const double xl4 = 40.0;
  static const double xl5 = 48.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// TIPOGRAFÍA — Inter (Google Fonts), mismos pesos que fonts.css
// Tamaños: xs=12, sm=14, base=16, lg=18, xl=20, 2xl=24, 3xl=30
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  // Encabezados (h1-h4, font-weight-medium = 500)
  static TextStyle get h1 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h2 => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h3 => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h4 => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);

  // Cuerpo (font-weight-normal = 400)
  static TextStyle get bodyLarge  => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.foreground);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.foreground);
  static TextStyle get bodySmall  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.mutedForeground);
  static TextStyle get bodyMuted  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.mutedForeground);

  // Labels y botones (font-weight-medium = 500)
  static TextStyle get label      => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get button     => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);

  // Display (para stats y contadores grandes)
  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600, height: 1.2, color: AppColors.foreground);
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMA MATERIAL — ThemeData oscuro de Bound2Game
// ─────────────────────────────────────────────────────────────────────────────

/// Retorna el [ThemeData] oscuro configurado con los tokens de diseño Bound2Game.
ThemeData buildAppTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.sidebarPrimary,
    onPrimary: AppColors.sidebarPrimaryForeground,
    primaryContainer: AppColors.surface,
    onPrimaryContainer: AppColors.foreground,
    secondary: AppColors.surface,
    onSecondary: AppColors.foreground,
    secondaryContainer: AppColors.sidebar,
    onSecondaryContainer: AppColors.foreground,
    tertiary: AppColors.sidebarPrimary,
    onTertiary: AppColors.sidebarPrimaryForeground,
    tertiaryContainer: AppColors.surface,
    onTertiaryContainer: AppColors.foreground,
    error: AppColors.destructiveForeground,
    onError: AppColors.destructive,
    errorContainer: AppColors.destructive,
    onErrorContainer: AppColors.destructiveForeground,
    surface: AppColors.card,
    onSurface: AppColors.foreground,
    surfaceContainerHighest: AppColors.surface,
    onSurfaceVariant: AppColors.mutedForeground,
    outline: AppColors.border,
    outlineVariant: AppColors.ring,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.primary,
    onInverseSurface: AppColors.primaryForeground,
    inversePrimary: AppColors.primaryForeground,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.sidebar,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.foreground),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.sidebar,
      selectedItemColor: AppColors.sidebarPrimary,
      unselectedItemColor: AppColors.mutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.sidebar,
      indicatorColor: AppColors.sidebarPrimary.withOpacity(0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.sidebarPrimary);
        }
        return const IconThemeData(color: AppColors.mutedForeground);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(color: AppColors.sidebarPrimary);
        }
        return AppTextStyles.bodyMuted;
      }),
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.sidebar,
      scrimColor: Colors.black54,
    ),

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sidebarPrimary,
        foregroundColor: AppColors.sidebarPrimaryForeground,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.border),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.sidebarPrimary,
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedForeground),
      border: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.sidebarPrimary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.labelSmall,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    ),

    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 0),

    iconTheme: const IconThemeData(color: AppColors.foreground, size: 24),

    textTheme: TextTheme(
      displayLarge:    AppTextStyles.displayLarge,
      headlineLarge:   AppTextStyles.h1,
      headlineMedium:  AppTextStyles.h2,
      headlineSmall:   AppTextStyles.h3,
      titleLarge:      AppTextStyles.h3,
      titleMedium:     AppTextStyles.h4,
      titleSmall:      AppTextStyles.label,
      bodyLarge:       AppTextStyles.bodyLarge,
      bodyMedium:      AppTextStyles.bodyMedium,
      bodySmall:       AppTextStyles.bodySmall,
      labelLarge:      AppTextStyles.label,
      labelMedium:     AppTextStyles.labelSmall,
      labelSmall:      AppTextStyles.bodyMuted,
    ),
  );
}
