import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../widgets/gradient_card.dart';
import '../../../../core/utils/date_utils.dart';

class CheckinDetailsModal extends StatelessWidget {
  final Map<String, dynamic> checkIn;

  const CheckinDetailsModal({
    super.key,
    required this.checkIn,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(checkIn['checkinDate'] ?? DateTime.now().toIso8601String());
    final clientName = checkIn['clientName'] ?? 'Unknown Client';
    final photoUrl = checkIn['photoUrl'];
    final weight = checkIn['weight'];
    final notes = checkIn['clientNotes'];
    final gps = checkIn['gpsCoordinates'];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-in Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Photo
              if (photoUrl != null) ...[
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Client Name
              _buildDetailRow(
                icon: Icons.person_rounded,
                label: 'Client',
                value: clientName,
              ),
              
              const SizedBox(height: 12),
              
              // Date
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: AppDateUtils.formatDisplayDate(date),
              ),
              
              const SizedBox(height: 12),
              
              // Weight
              if (weight != null) ...[
                _buildDetailRow(
                  icon: Icons.monitor_weight_rounded,
                  label: 'Weight',
                  value: '$weight kg',
                ),
                const SizedBox(height: 12),
              ],
              
              // GPS Coordinates
              if (gps != null) ...[
                _buildDetailRow(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  value: 'Lat: ${gps['lat']}, Lng: ${gps['lng']}',
                ),
                const SizedBox(height: 12),
              ],
              
              // Notes
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

