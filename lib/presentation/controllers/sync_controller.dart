import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_controller.g.dart';

@riverpod
class SyncController extends _$SyncController {
  @override
  FutureOr<void> build() async {
    // Initialize sync service
  }
  
  Future<void> sync() async {
    // Trigger sync
    // This will be implemented with SyncManager
  }
}

