class User {
  final String id;
  final String email;
  final String role; // 'CLIENT' | 'TRAINER'
  final String name;
  final DateTime lastSync;
  
  User({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.lastSync,
  });
}

