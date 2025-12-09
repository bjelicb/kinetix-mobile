import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports - only import Isar schemas on non-web platforms
import '../data/models/user_collection.dart' if (dart.library.html) '../data/models/user_collection_stub.dart';
import '../data/models/workout_collection.dart' if (dart.library.html) '../data/models/workout_collection_stub.dart';
import '../data/models/exercise_collection.dart' if (dart.library.html) '../data/models/exercise_collection_stub.dart';
import '../data/models/checkin_collection.dart' if (dart.library.html) '../data/models/checkin_collection_stub.dart';
import '../data/models/plan_collection.dart' if (dart.library.html) '../data/models/plan_collection_stub.dart';

class IsarService {
  static Isar? _isar;
  
  static Future<Isar?> get instance async {
    // Isar doesn't work on web - generates large integers that can't be represented in JavaScript
    if (kIsWeb) {
      return null;
    }
    
    if (_isar != null) {
      return _isar!;
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Use dynamic to avoid type errors with schemas
      _isar = await Isar.open(
        [
          UserCollectionSchema as dynamic,
          WorkoutCollectionSchema as dynamic,
          ExerciseCollectionSchema as dynamic,
          CheckInCollectionSchema as dynamic,
          PlanCollectionSchema as dynamic,
        ],
        directory: dir.path,
      );
      
      return _isar!;
    } catch (e) {
      // If Isar fails, return null
      return null;
    }
  }
  
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}

