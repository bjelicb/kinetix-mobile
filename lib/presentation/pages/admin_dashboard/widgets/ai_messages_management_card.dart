import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../../../../domain/entities/ai_message.dart';
import '../../../widgets/cyber_loader.dart';
import '../../../widgets/gradient_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/search_bar.dart' as kinetix_search;
import 'filter_chip.dart';
import 'ai_message_list_item.dart';

class AIMessagesManagementCard extends StatelessWidget {
  final VoidCallback onCreateMessage;
  final ValueChanged<String> onSearchChanged;
  final String toneFilter; // 'ALL', 'MOTIVATIONAL', 'WARNING', 'AGGRESSIVE', 'EMPATHETIC'
  final ValueChanged<String> onToneFilterChanged;
  final bool isLoading;
  final List<AIMessage> messages;

  const AIMessagesManagementCard({
    super.key,
    required this.onCreateMessage,
    required this.onSearchChanged,
    required this.toneFilter,
    required this.onToneFilterChanged,
    required this.isLoading,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      showCyberBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: AppColors.textSecondary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'AI Messages',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
              NeonButton(
                text: 'Create',
                icon: Icons.add_rounded,
                onPressed: onCreateMessage,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          kinetix_search.SearchBar(hintText: 'Search messages...', onChanged: onSearchChanged),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DashboardFilterChip(
                  label: 'All',
                  selected: toneFilter == 'ALL',
                  onSelected: (_) => onToneFilterChanged('ALL'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Motivational',
                  selected: toneFilter == 'MOTIVATIONAL',
                  onSelected: (_) => onToneFilterChanged('MOTIVATIONAL'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Warning',
                  selected: toneFilter == 'WARNING',
                  onSelected: (_) => onToneFilterChanged('WARNING'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Aggressive',
                  selected: toneFilter == 'AGGRESSIVE',
                  onSelected: (_) => onToneFilterChanged('AGGRESSIVE'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Empathetic',
                  selected: toneFilter == 'EMPATHETIC',
                  onSelected: (_) => onToneFilterChanged('EMPATHETIC'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Center(
              child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: AnimatedCyberLoader(size: 40)),
            )
          else if (messages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('No messages found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ),
            )
          else
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return AIMessageListItem(message: messages[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}
