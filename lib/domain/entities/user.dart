class User {
  final String id;
  final String email;
  final String role; // 'CLIENT' | 'TRAINER' | 'ADMIN'
  final String name;
  final String? trainerName; // Assigned trainer for clients
  final String? trainerId; // Trainer ID for clients
  final String? clientProfileId; // Client profile ID for clients (used for plan assignment)
  final DateTime lastSync;
  final bool isActive; // User active status
  
  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.trainerName,
    this.trainerId,
    this.clientProfileId,
    required this.lastSync,
    this.isActive = true, // Default to active
  });
}

