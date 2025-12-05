import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/haptic_feedback.dart';
import 'gradient_card.dart';

class Appointment {
  final String id;
  final String clientName;
  final String clientId;
  final DateTime time;
  final String? notes;

  Appointment({
    required this.id,
    required this.clientName,
    required this.clientId,
    required this.time,
    this.notes,
  });
}

class AppointmentsCard extends StatelessWidget {
  final List<Appointment> appointments;
  final Function(String appointmentId)? onAppointmentTap;

  const AppointmentsCard({
    super.key,
    this.appointments = const [],
    this.onAppointmentTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mock appointments if empty
    final displayAppointments = appointments.isEmpty ? _getMockAppointments() : appointments;
    
    // Filter today's appointments
    final today = DateTime.now();
    final todayAppointments = displayAppointments.where((apt) {
      return apt.time.year == today.year &&
          apt.time.month == today.month &&
          apt.time.day == today.day;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    if (todayAppointments.isEmpty) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No appointments today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'You have a free schedule',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Appointments",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${todayAppointments.length}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...todayAppointments.map((apt) => _buildAppointmentItem(context, apt)),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, Appointment appointment) {
    final isPast = appointment.time.isBefore(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          AppHaptic.light();
          if (onAppointmentTap != null) {
            onAppointmentTap!(appointment.id);
          } else {
            // Navigate to client profile (placeholder)
            context.go('/client/${appointment.clientId}');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPast
                  ? AppColors.textSecondary.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Time
              Container(
                width: 60,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isPast ? AppGradients.card : AppGradients.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(appointment.time),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatAmPm(appointment.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.clientName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        appointment.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Quick Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.phone_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      AppHaptic.light();
                      // TODO: Implement call functionality
                    },
                    tooltip: 'Call',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.message_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      AppHaptic.light();
                      // TODO: Implement message functionality
                    },
                    tooltip: 'Message',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAmPm(DateTime time) {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  List<Appointment> _getMockAppointments() {
    final now = DateTime.now();
    return [
      Appointment(
        id: '1',
        clientName: 'John Doe',
        clientId: 'client1',
        time: DateTime(now.year, now.month, now.day, 10, 0),
        notes: 'Strength training session',
      ),
      Appointment(
        id: '2',
        clientName: 'Jane Smith',
        clientId: 'client2',
        time: DateTime(now.year, now.month, now.day, 14, 30),
        notes: 'Cardio and flexibility',
      ),
      Appointment(
        id: '3',
        clientName: 'Mike Johnson',
        clientId: 'client3',
        time: DateTime(now.year, now.month, now.day, 16, 0),
      ),
    ];
  }
}

