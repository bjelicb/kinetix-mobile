import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart' show AppColors;
import '../../../../domain/entities/ai_message.dart';
import '../../../widgets/gradient_card.dart';

class AIMessageListItem extends StatelessWidget {
  final AIMessage message;
  final String? clientName; // Optional client name if available

  const AIMessageListItem({
    super.key,
    required this.message,
    this.clientName,
  });

  Color _getToneColor(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.motivational:
        return AppColors.success;
      case AIMessageTone.warning:
        return AppColors.warning;
      case AIMessageTone.aggressive:
        return AppColors.error;
      case AIMessageTone.empathetic:
        return AppColors.info;
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

  @override
  Widget build(BuildContext context) {
    final toneColor = _getToneColor(message.tone);
    final toneIcon = _getToneIcon(message.tone);

    return GradientCard(
      gradient: LinearGradient(
        colors: [
          toneColor.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ),
      borderColor: toneColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Tone icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(toneIcon, color: toneColor, size: 16),
          ),
          const SizedBox(width: 12),
          // Message info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (clientName != null)
                  Text(
                    clientName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (clientName != null) const SizedBox(height: 4),
                Text(
                  message.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 10,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(message.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Read status
          if (!message.isRead)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: toneColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'UNREAD',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

