import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Figma 값으로 만든 앱 테마. 위젯은 가능하면 이 테마를 쓰고, 테마로 안 되는 값만 [AppColors] 등을 직접 쓴다.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outlineVariant: AppColors.divider,
          error: AppColors.caution,
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    const buttonSize = Size.fromHeight(AppSpace.buttonHeight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textStatus,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppText.toolbar,
      ),
      textTheme: const TextTheme(
        headlineMedium: AppText.headline,
        titleLarge: AppText.title,
        titleMedium: AppText.section,
        titleSmall: AppText.listTitle,
        bodyMedium: AppText.body,
        bodySmall: AppText.caption,
        labelLarge: AppText.button,
      ),
      // 주 버튼: "다음 단계", "이 화면 분석하기" 등
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppText.button,
        ),
      ),
      // 보조 버튼: "화면이 달라요 · 다시 분석", "다른 이미지 선택" 등
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.secondaryButton,
          foregroundColor: AppColors.textTertiary,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppText.button,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
