import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../controllers/analytics_controller.dart';
import '../../pages/analytics/utils/client_utils.dart';
import '../gradient_card.dart';
import '../shimmer_loader.dart';

/// Widget for clients tab showing list of clients
class ClientsTabWidget extends ConsumerWidget {
  final String? selectedClientId;
  final Function(String, String) onClientSelected;

  const ClientsTabWidget({
    super.key,
    required this.selectedClientId,
    required this.onClientSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsState = ref.watch(analyticsControllerProvider);

    return clientsState.when(
      data: (clients) {
        if (clients.isEmpty) {
          return Center(
            child: Text(
              'No clients available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: clients.map((client) {
            final clientId = ClientUtils.extractClientId(client);
            final clientName = ClientUtils.extractClientName(client);

            if (clientId.isEmpty || clientName.isEmpty) {
              return const SizedBox.shrink();
            }

            return GradientCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              gradient: AppGradients.card,
              onTap: () {
                onClientSelected(clientId, clientName);
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        clientName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View progress and statistics',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (selectedClientId == clientId)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: List.generate(3, (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 80),
        )),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error loading clients: $error',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

