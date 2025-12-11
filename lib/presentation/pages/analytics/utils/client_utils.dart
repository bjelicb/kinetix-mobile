/// Utility functions for parsing client data
class ClientUtils {
  /// Extracts client ID from various data formats
  static String extractClientId(Map<String, dynamic> client) {
    return client['_id']?.toString() ?? client['id']?.toString() ?? '';
  }

  /// Extracts client name from various data formats
  static String extractClientName(Map<String, dynamic> client) {
    final name = client['name']?.toString();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    
    final firstName = client['firstName']?.toString() ?? '';
    final lastName = client['lastName']?.toString() ?? '';
    return '$firstName $lastName'.trim();
  }

  /// Builds a map of client IDs to client names
  static Map<String, String> buildClientMap(List<Map<String, dynamic>> clients) {
    final clientMap = <String, String>{};
    for (final client in clients) {
      final id = extractClientId(client);
      final name = extractClientName(client);
      if (id.isNotEmpty && name.isNotEmpty) {
        clientMap[id] = name;
      }
    }
    return clientMap;
  }
}

