import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import 'gradient_card.dart';
import 'package:intl/intl.dart';

class AIMessageCard extends StatelessWidget {
  final AIMessage message;
  final VoidCallback? onTap;
  
  const AIMessageCard({
    super.key,
    required this.message,
    this.onTap,
  });

  Color _getToneColor(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.aggressive:
        return AppColors.error;
      case AIMessageTone.empathetic:
        return AppColors.info;
      case AIMessageTone.motivational:
        return AppColors.success;
      case AIMessageTone.warning:
        return AppColors.warning;
    }
  }

  IconData _getToneIcon(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.aggressive:
        return Icons.warning_rounded;
      case AIMessageTone.empathetic:
        return Icons.favorite_rounded;
      case AIMessageTone.motivational:
        return Icons.trending_up_rounded;
      case AIMessageTone.warning:
        return Icons.info_rounded;
    }
  }

  String _getToneLabel(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.aggressive:
        return 'PUSH HARDER';
      case AIMessageTone.empathetic:
        return 'SUPPORTIVE';
      case AIMessageTone.motivational:
        return 'MOTIVATIONAL';
      case AIMessageTone.warning:
        return 'ATTENTION';
    }
  }

  TextStyle _getToneStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    
    switch (message.tone) {
      case AIMessageTone.aggressive:
        return baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 15,
        );
      case AIMessageTone.empathetic:
        return baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.textPrimary,
        );
      case AIMessageTone.motivational:
        return baseStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 15,
        );
      case AIMessageTone.warning:
        return baseStyle.copyWith(
          color: AppColors.textPrimary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final toneColor = _getToneColor(message.tone);
    
    return GestureDetector(
      onTap: onTap,
      child: GradientCard(
        gradient: LinearGradient(
          colors: [
            toneColor.withValues(alpha: 0.2),
            toneColor.withValues(alpha: 0.1),
          ],
        ),
        borderColor: toneColor,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getToneIcon(message.tone),
                    color: toneColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getToneLabel(message.tone),
                        style: TextStyle(
                          color: toneColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(message.createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!message.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: toneColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message.message,
              style: _getToneStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

