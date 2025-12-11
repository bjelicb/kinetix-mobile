import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../controllers/analytics_controller.dart';
import '../../pages/analytics/utils/client_utils.dart';
import '../gradient_card.dart';
import '../shimmer_loader.dart';

/// Widget for client selection dropdown with auto-selection
class ClientSelectionDropdownWidget extends ConsumerStatefulWidget {
  final String? selectedClientId;
  final Function(String, String) onClientSelected;

  const ClientSelectionDropdownWidget({
    super.key,
    required this.selectedClientId,
    required this.onClientSelected,
  });

  @override
  ConsumerState<ClientSelectionDropdownWidget> createState() => _ClientSelectionDropdownWidgetState();
}

class _ClientSelectionDropdownWidgetState extends ConsumerState<ClientSelectionDropdownWidget> {
  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(analyticsControllerProvider);

    return clientsState.when(
      data: (clients) {
        if (clients.isEmpty) {
          return GradientCard(
            gradient: AppGradients.card,
            padding: const EdgeInsets.all(16),
            child: Text(
              'No clients found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          );
        }

        // Auto-select first client if none selected
        if (widget.selectedClientId == null && clients.isNotEmpty) {
          final firstClient = clients.first;
          final clientId = ClientUtils.extractClientId(firstClient);
          final clientName = ClientUtils.extractClientName(firstClient);
          if (clientId.isNotEmpty && clientName.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onClientSelected(clientId, clientName);
            });
          }
        }

        final clientMap = ClientUtils.buildClientMap(clients);

        return GradientCard(
          gradient: AppGradients.card,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<String>(
            value: widget.selectedClientId,
            isExpanded: true,
            underline: Container(),
            dropdownColor: AppColors.surface,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
            items: clientMap.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && clientMap.containsKey(value)) {
                widget.onClientSelected(value, clientMap[value]!);
              }
            },
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primary,
            ),
          ),
        );
      },
      loading: () => const ShimmerCard(height: 60),
      error: (error, stack) => GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error loading clients: $error',
          style: TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

