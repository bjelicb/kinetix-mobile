import '../../../../core/utils/export_service.dart';

/// Export result
class ExportResult {
  final bool success;
  final String? error;
  final String? successMessage;

  ExportResult({
    required this.success,
    this.error,
    this.successMessage,
  });
}

/// Service wrapper for export operations
class SettingsExportService {
  /// Exports workouts to CSV format
  static Future<ExportResult> exportToCSV() async {
    try {
      final csvData = await ExportService.instance.exportWorkoutsToCSV();
      if (csvData != null) {
        await ExportService.instance.shareExportedData(
          csvData,
          'kinetix_workouts_${DateTime.now().millisecondsSinceEpoch}.csv',
          'text/csv',
        );
        return ExportResult(
          success: true,
          successMessage: 'Workouts exported to CSV',
        );
      }
      return ExportResult(
        success: false,
        error: 'Failed to generate CSV data',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Exports workouts to JSON format
  static Future<ExportResult> exportToJSON() async {
    try {
      final jsonData = await ExportService.instance.exportWorkoutsToJSON();
      if (jsonData != null) {
        await ExportService.instance.shareJSONData(
          jsonData,
          'kinetix_workouts_${DateTime.now().millisecondsSinceEpoch}.json',
        );
        return ExportResult(
          success: true,
          successMessage: 'Workouts exported to JSON',
        );
      }
      return ExportResult(
        success: false,
        error: 'Failed to generate JSON data',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

