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
  // ── Fondos ────────────────────────────────────────────────────────────────
  /// Fondo principal: Negro puro (#000000)
  static const Color background      = Color(0xFF000000);
  /// Superficie de tarjetas: Gris oscuro (#282828)
  static const Color card            = Color(0xFF282828);
  /// Sidebar / barra de navegación
  static const Color sidebar         = Color(0xFF000000);
  /// Surface secundaria (chips, inputs resting)
  static const Color surface         = Color(0xFF333333);
  /// Fondo de campos de texto
  static const Color inputBackground = Color(0xFF111111);

  // ── Primer plano ──────────────────────────────────────────────────────────
  /// Texto principal: Blanco puro (#FFFFFF)
  static const Color foreground      = Color(0xFFFFFFFF);
  /// Texto secundario / muted
  static const Color mutedForeground = Color(0xFFAAAAAA);

  // ── Primario (blanco suave para textos sobre acento) ──────────────────────
  static const Color primary            = Color(0xFFFFFFFF);
  static const Color primaryForeground  = Color(0xFF000000);

  // ── Acento principal: Amarillo (#FFE600) ──────────────────────────────
  /// Color de acento global — botones, bordes activos, íconos seleccionados.
  static const Color accent            = Color(0xFFFFE600);
  /// Variante clara/secundaria del acento para gradientes (#FFF566)
  static const Color accentDark        = Color(0xFFFFF566);
  /// Foreground sobre botones de acento (negro para contraste)
  static const Color accentForeground  = Color(0xFF000000);

  // Alias semántico: sidebarPrimary ahora apunta al acento amarillo
  static const Color sidebarPrimary            = accent;
  static const Color sidebarPrimaryForeground  = accentForeground;

  // ── Destructivo ───────────────────────────────────────────────────────────
  static const Color destructive           = Color(0xFF8B2020);
  static const Color destructiveForeground = Color(0xFFFF6B6B);

  // ── Bordes ────────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A);
  static const Color ring   = Color(0xFF3A3A3A);

  // ── Reputación (REPUTATION_CONFIG en gameData.ts) ─────────────────────────
  static const Color repLegendary = Color(0xFFFFD700);
  static const Color repExemplar  = Color(0xFF4AF626);
  static const Color repPositive  = Color(0xFF00E5FF);
  static const Color repNeutral   = Color(0xFF888888);
  static const Color repNegative  = Color(0xFFFF4040);

  static Color repLegendaryBg = const Color(0xFFFFD700).withValues(alpha: 0.15);
  static Color repExemplarBg  = const Color(0xFF4AF626).withValues(alpha: 0.15);
  static Color repPositiveBg  = const Color(0xFF00E5FF).withValues(alpha: 0.15);
  static Color repNeutralBg   = const Color(0xFF888888).withValues(alpha: 0.15);
  static Color repNegativeBg  = const Color(0xFFFF4040).withValues(alpha: 0.15);

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
    // Acento principal: Amarillo B2G
    primary:            AppColors.accent,
    onPrimary:          AppColors.accentForeground,
    primaryContainer:   AppColors.surface,
    onPrimaryContainer: AppColors.foreground,
    secondary:          AppColors.surface,
    onSecondary:        AppColors.foreground,
    secondaryContainer: AppColors.sidebar,
    onSecondaryContainer: AppColors.foreground,
    tertiary:           AppColors.accent,
    onTertiary:         AppColors.accentForeground,
    tertiaryContainer:  AppColors.surface,
    onTertiaryContainer: AppColors.foreground,
    error:              AppColors.destructiveForeground,
    onError:            AppColors.destructive,
    errorContainer:     AppColors.destructive,
    onErrorContainer:   AppColors.destructiveForeground,
    surface:            AppColors.card,
    onSurface:          AppColors.foreground,
    surfaceContainerHighest: AppColors.surface,
    onSurfaceVariant:   AppColors.mutedForeground,
    outline:            AppColors.border,
    outlineVariant:     AppColors.ring,
    shadow:             Colors.black,
    scrim:              Colors.black,
    inverseSurface:     AppColors.primary,
    onInverseSurface:   AppColors.primaryForeground,
    inversePrimary:     AppColors.primaryForeground,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background, // Negro puro #000000

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF292929),
      surfaceTintColor: Colors.transparent, // Evita cambio de color al hacer scroll
      foregroundColor: AppColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 8.0,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.foreground),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF292929),
      selectedItemColor: AppColors.accent,       // Ítem seleccionado: Amarillo
      unselectedItemColor: AppColors.mutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      // Aplicamos sombra para mantener la coherencia de "deslizamiento"
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF292929),
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      indicatorColor: AppColors.accent.withValues(alpha: 0.18), // Indicador amarillo suave
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.accent); // Ícono activo: Amarillo
        }
        return const IconThemeData(color: AppColors.mutedForeground);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.labelSmall.copyWith(color: AppColors.accent);
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
        backgroundColor: AppColors.accent,           // Botón principal: Amarillo
        foregroundColor: AppColors.accentForeground,  // Texto: Negro (contraste AAA)
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
        foregroundColor: AppColors.accent, // TextButton: Amarillo
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedForeground),
      border: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.roundedMd, borderSide: const BorderSide(color: AppColors.accent, width: 2)), // Borde activo: Amarillo
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
