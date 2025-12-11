import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../gradient_card.dart';

/// Reusable widget for settings sections (ExpansionTile wrapper)
class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(title),
        leading: Icon(icon, color: AppColors.primary),
        children: children,
      ),
    );
  }
}

