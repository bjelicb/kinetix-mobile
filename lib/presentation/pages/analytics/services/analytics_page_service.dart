import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/analytics_controller.dart';

/// Service for analytics page operations
class AnalyticsPageService {
  /// Loads client analytics data
  static Future<ClientAnalytics?> loadClientAnalytics(
    WidgetRef ref,
    String clientId,
    String clientName,
  ) async {
    try {
      final controller = ref.read(analyticsControllerProvider.notifier);
      return await controller.getClientAnalytics(clientId, clientName);
    } catch (e) {
      return null;
    }
  }
}

