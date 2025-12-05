class CheckIn {
  final String id;
  final String photoLocalPath;
  final String? photoUrl;
  final DateTime timestamp;
  final bool isSynced;
  
  CheckIn({
    required this.id,
    required this.photoLocalPath,
    this.photoUrl,
    required this.timestamp,
    required this.isSynced,
  });
}

