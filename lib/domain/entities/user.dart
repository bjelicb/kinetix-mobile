class User {
  final String id;
  final String email;
  final String role; // 'CLIENT' | 'TRAINER' | 'ADMIN'
  final String name;
  final String? trainerName; // Assigned trainer for clients
  final String? trainerId; // Trainer ID for clients
  final DateTime lastSync;
  final bool isActive; // User active status
  
  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.trainerName,
    this.trainerId,
    required this.lastSync,
    this.isActive = true, // Default to active
  });
}

