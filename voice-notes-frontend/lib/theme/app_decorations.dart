import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  // Card decorations
  static final BoxDecoration card = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        offset: const Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ],
  );

  static final BoxDecoration noteCard = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        offset: const Offset(0, 1),
        blurRadius: 3,
      ),
    ],
  );

  // Input borders
  static final OutlineInputBorder inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  );

  static final OutlineInputBorder inputBorderFocused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(
      color: AppColors.primary,
      width: 2,
    ),
  );

  // Container decorations
  static BoxDecoration circularContainer(Color color) => BoxDecoration(
    color: color,
    shape: BoxShape.circle,
  );

  static BoxDecoration roundedContainer({
    Color color = AppColors.surface,
    double radius = 8,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
  );

  // Modal decoration
  static const BoxDecoration bottomSheet = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
  );
}

class AppSpacing {
  // Padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  
  // Gaps
  static const SizedBox gap4 = SizedBox(height: 4);
  static const SizedBox gap8 = SizedBox(height: 8);
  static const SizedBox gap12 = SizedBox(height: 12);
  static const SizedBox gap16 = SizedBox(height: 16);
  static const SizedBox gap24 = SizedBox(height: 24);
  static const SizedBox gap32 = SizedBox(height: 32);
  
  // Horizontal gaps
  static const SizedBox hGap4 = SizedBox(width: 4);
  static const SizedBox hGap8 = SizedBox(width: 8);
  static const SizedBox hGap12 = SizedBox(width: 12);
  static const SizedBox hGap16 = SizedBox(width: 16);
}