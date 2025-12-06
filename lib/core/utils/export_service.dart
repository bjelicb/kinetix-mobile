import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path_provider/path_provider.dart';
import '../../data/datasources/local_data_source.dart';

class ExportService {
  static ExportService? _instance;
  static ExportService get instance {
    _instance ??= ExportService._();
    return _instance!;
  }

  ExportService._();

  final LocalDataSource _localDataSource = LocalDataSource();

  /// Export workouts to CSV format
  Future<String?> exportWorkoutsToCSV() async {
    try {
      final workouts = await _localDataSource.getWorkouts();
      if (workouts.isEmpty) {
        return null;
      }

      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('Workout ID,Name,Scheduled Date,Completed,Exercise Count,Total Sets');
      
      for (final workout in workouts) {
        final exercises = await _localDataSource.getExercisesForWorkout(workout.id);
        final totalSets = exercises.fold<int>(
          0,
          (sum, exercise) => sum + exercise.sets.length,
        );
        
        buffer.writeln([
          workout.id,
          _escapeCsvField(workout.name),
          workout.scheduledDate.toIso8601String(),
          workout.isCompleted ? 'Yes' : 'No',
          exercises.length,
          totalSets,
        ].join(','));
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error exporting workouts to CSV: $e');
      return null;
    }
  }

  /// Export workouts to JSON format
  Future<Map<String, dynamic>?> exportWorkoutsToJSON() async {
    try {
      final workouts = await _localDataSource.getWorkouts();
      if (workouts.isEmpty) {
        return null;
      }

      final workoutsJson = <Map<String, dynamic>>[];
      
      for (final workout in workouts) {
        final exercises = await _localDataSource.getExercisesForWorkout(workout.id);
        final exercisesJson = exercises.map((exercise) {
          return {
            'id': exercise.id.toString(),
            'name': exercise.name,
            'targetMuscle': exercise.targetMuscle,
            'sets': exercise.sets.map((set) {
              return {
                'id': set.id,
                'weight': set.weight,
                'reps': set.reps,
                'rpe': set.rpe,
                'isCompleted': set.isCompleted,
              };
            }).toList(),
          };
        }).toList();

        workoutsJson.add({
          'id': workout.id.toString(),
          'serverId': workout.serverId,
          'name': workout.name,
          'scheduledDate': workout.scheduledDate.toIso8601String(),
          'isCompleted': workout.isCompleted,
          'updatedAt': workout.updatedAt.toIso8601String(),
          'exercises': exercisesJson,
        });
      }

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'workouts': workoutsJson,
      };
    } catch (e) {
      debugPrint('Error exporting workouts to JSON: $e');
      return null;
    }
  }

  /// Export check-ins to CSV format
  Future<String?> exportCheckInsToCSV() async {
    try {
      final checkIns = await _localDataSource.getAllCheckIns();
      if (checkIns.isEmpty) {
        return null;
      }

      final buffer = StringBuffer();
      
      // CSV Header
      buffer.writeln('Check-In ID,Timestamp,Photo URL,Synced');
      
      for (final checkIn in checkIns) {
        buffer.writeln([
          checkIn.id,
          checkIn.timestamp.toIso8601String(),
          checkIn.photoUrl ?? '',
          checkIn.isSynced ? 'Yes' : 'No',
        ].join(','));
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Error exporting check-ins to CSV: $e');
      return null;
    }
  }

  /// Get storage usage breakdown
  Future<Map<String, int>> getStorageUsage() async {
    try {
      final workouts = await _localDataSource.getWorkouts();
      final checkIns = await _localDataSource.getAllCheckIns();
      final users = await _localDataSource.getUsers();

      return {
        'workouts': workouts.length,
        'checkIns': checkIns.length,
        'users': users.length,
      };
    } catch (e) {
      debugPrint('Error getting storage usage: $e');
      return {};
    }
  }

  /// Share exported data
  Future<void> shareExportedData(String data, String filename, String mimeType) async {
    try {
      if (kIsWeb) {
        // Web: Download file using download attribute
        debugPrint('Web export: $filename');
        // Note: Web implementation would need html package
        return;
      }

      // Mobile: Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = io.File('${tempDir.path}/$filename');
      await file.writeAsString(data);
      
      // For now, just save the file path
      // Share functionality can be added later with share_plus
      debugPrint('Exported data saved to: ${file.path}');
    } catch (e) {
      debugPrint('Error sharing exported data: $e');
    }
  }

  /// Share JSON data
  Future<void> shareJSONData(Map<String, dynamic> data, String filename) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await shareExportedData(jsonString, filename, 'application/json');
    } catch (e) {
      debugPrint('Error sharing JSON data: $e');
    }
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
