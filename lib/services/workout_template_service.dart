import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import '../data/models/workout_template.dart';

class WorkoutTemplateService {
  static WorkoutTemplateService? _instance;
  static WorkoutTemplateService get instance {
    _instance ??= WorkoutTemplateService._();
    return _instance!;
  }

  WorkoutTemplateService._();

  List<WorkoutTemplate>? _cachedTemplates;
  bool _isLoading = false;

  Future<List<WorkoutTemplate>> loadTemplates() async {
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    if (_isLoading) {
      // Wait for ongoing load
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedTemplates ?? [];
    }

    _isLoading = true;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/workout_templates.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> templatesJson =
          jsonData['templates'] as List<dynamic>;

      _cachedTemplates = templatesJson.map((json) {
        return WorkoutTemplate.fromJson(json as Map<String, dynamic>);
      }).toList();

      debugPrint('Loaded ${_cachedTemplates!.length} workout templates');
      return _cachedTemplates!;
    } catch (e) {
      debugPrint('Error loading workout templates: $e');
      return [];
    } finally {
      _isLoading = false;
    }
  }

  Future<WorkoutTemplate?> getTemplateById(String id) async {
    final templates = await loadTemplates();
    try {
      return templates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<WorkoutTemplate>> getAllTemplates() async {
    return await loadTemplates();
  }

  Future<List<WorkoutTemplate>> searchTemplates(String query) async {
    final templates = await loadTemplates();
    if (query.isEmpty) {
      return templates;
    }

    final lowerQuery = query.toLowerCase();
    return templates.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
          template.description.toLowerCase().contains(lowerQuery) ||
          template.exercises.any((exercise) =>
              exercise.name.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  void clearCache() {
    _cachedTemplates = null;
  }
}
