// Aquí es donde defino el estilo de toda la app. He elegido colores oscuros y un amarillo potente porque queda muy gaming y profesional.
// Me he basado en un diseño moderno de "modo oscuro" puro para que no canse la vista al jugar de noche.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Esta es mi paleta de colores oficial. El negro puro para el fondo y el amarillo Bound2Game para destacar lo importante.
abstract final class AppColors {
  // Fondos: Negro puro y grises muy oscuros.
  static const Color background      = Color(0xFF000000);
  static const Color card            = Color(0xFF282828);
  static const Color sidebar         = Color(0xFF000000);
  static const Color surface         = Color(0xFF333333);
  static const Color inputBackground = Color(0xFF111111);

  // Textos: Blanco para que resalte y grises para lo menos importante.
  static const Color foreground      = Color(0xFFFFFFFF);
  static const Color mutedForeground = Color(0xFFAAAAAA);

  static const Color primary            = Color(0xFFFFFFFF);
  static const Color primaryForeground  = Color(0xFF000000);

  // El amarillo Bound2Game. Es el alma de la app.
  static const Color accent            = Color(0xFFFFE600);
  static const Color accentDark        = Color(0xFFFFF566);
  static const Color accentForeground  = Color(0xFF000000);

  static const Color sidebarPrimary            = accent;
  static const Color sidebarPrimaryForeground  = accentForeground;

  // Rojo para cuando algo va mal o queremos borrar algo.
  static const Color destructive           = Color(0xFF8B2020);
  static const Color destructiveForeground = Color(0xFFFF6B6B);

  static const Color border = Color(0xFF2A2A2A);
  static const Color ring   = Color(0xFF3A3A3A);

  // Colores para el sistema de reputación de los usuarios.
  static const Color repLegendary = Color(0xFFFFD700);
  static const Color repExemplar  = Color(0xFF4AF626);
  static const Color repPositive  = Color(0xFF00E5FF);
  static const Color repNeutral   = Color(0xFF888888);
  static const Color repNegative  = Color(0xFFFF4040);

  // Colores oficiales de las plataformas de juegos.
  static const Color platformSteam = Color(0xFF1B9ED9);
  static const Color platformEpic  = Color(0xFFFFFFFF);
  static const Color platformIg    = Color(0xFFFF6B00);
  static const Color platformB2g   = Color(0xFF9B59B6);

  // El semáforo de requisitos de PC.
  static const Color pcReqGreen  = Color(0xFF4AF626);
  static const Color pcReqYellow = Color(0xFFFFB800);
  static const Color pcReqRed    = Color(0xFFFF4040);
}

// Los bordes redondeados. Me gusta que la app tenga un toque suave, así que nada de esquinas afiladas.
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

// Para que los márgenes y rellenos sean siempre iguales y todo quede bien alineado.
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

// La tipografía de la app. Uso la fuente "Inter" porque es moderna y se lee de lujo.
abstract final class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h2 => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h3 => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get h4 => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);

  static TextStyle get bodyLarge  => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.foreground);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.foreground);
  static TextStyle get bodySmall  => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.mutedForeground);
  static TextStyle get bodyMuted  => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.mutedForeground);

  static TextStyle get label      => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);
  static TextStyle get button     => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5, color: AppColors.foreground);

  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w600, height: 1.2, color: AppColors.foreground);
}

// Aquí junto todo para crear el tema oficial de la app. Configuro botones, barras y textos.
ThemeData buildAppTheme() {
  final ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.dark,
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
    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF292929),
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      titleTextStyle: AppTextStyles.h3,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: const IconThemeData(color: AppColors.foreground),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF292929),
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.mutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg, side: const BorderSide(color: AppColors.border)),
      margin: const EdgeInsets.all(AppSpacing.sm),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentForeground,
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
    ),

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
