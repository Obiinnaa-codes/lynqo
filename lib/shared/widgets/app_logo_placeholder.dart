import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radii.dart';

class AppLogoPlaceholder extends StatelessWidget {
  const AppLogoPlaceholder({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoBackground,
        borderRadius: BorderRadius.circular(AppRadii.logo),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.router_outlined,
        size: 36,
        color: AppColors.textPrimary,
      ),
    );
  }
}
