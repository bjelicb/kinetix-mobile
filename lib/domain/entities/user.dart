class User {
  final String id;
  final String email;
  final String role; // 'CLIENT' | 'TRAINER' | 'ADMIN'
  final String name;
  final String? trainerName; // Assigned trainer for clients
  final String? trainerId; // Trainer ID for clients
  final String? clientProfileId; // Client profile ID for clients (used for plan assignment)
  final String? currentPlanId; // Current unlocked plan ID (CLIENT only)
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
    this.currentPlanId,
    required this.lastSync,
    this.isActive = true, // Default to active
  });
  
  User copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? trainerName,
    String? trainerId,
    String? clientProfileId,
    String? currentPlanId,
    DateTime? lastSync,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      trainerName: trainerName ?? this.trainerName,
      trainerId: trainerId ?? this.trainerId,
      clientProfileId: clientProfileId ?? this.clientProfileId,
      currentPlanId: currentPlanId ?? this.currentPlanId,
      lastSync: lastSync ?? this.lastSync,
      isActive: isActive ?? this.isActive,
    );
  }
}

