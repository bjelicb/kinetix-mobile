import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../services/sync_manager.dart';
import '../../core/utils/shared_preferences_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late AuthRepository _repository;
  late LocalDataSource _localDataSource;
  late RemoteDataSource _remoteDataSource;

  @override
  FutureOr<User?> build() async {
    final storage = FlutterSecureStorage();
    _localDataSource = LocalDataSource();
    final dio = Dio();
    _remoteDataSource = RemoteDataSource(dio, storage);
    // Use real backend
    _repository = AuthRepositoryImpl(_localDataSource, _remoteDataSource, storage);

    final user = await _repository.getCurrentUser();

    // Auto-sync on app startup if user is logged in (mobile only)
    if (user != null && !kIsWeb) {
      _triggerInitialSync();
    }

    return user;
  }

  Future<User> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);

      // Fetch full profile for CLIENT users to get currentPlanId
      User finalUser = user;
      if (user.role == 'CLIENT') {
        try {
          final profileData = await _remoteDataSource.getClientProfile(user.id);
          final currentPlanId = profileData['currentPlanId']?.toString();

          // Merge currentPlanId into user
          finalUser = user.copyWith(currentPlanId: currentPlanId);

          // Save updated user locally
          final userCollection = await _localDataSource.getUserByServerId(user.id);
          if (userCollection != null) {
            userCollection.currentPlanId = currentPlanId;
            await _localDataSource.saveUser(userCollection);
          }

          debugPrint('[AuthController] ✓ Fetched currentPlanId: $currentPlanId');
        } catch (e) {
          debugPrint('[AuthController] ⚠️ Failed to fetch profile: $e');
          // Continue with user without currentPlanId
        }
      }

      state = AsyncValue.data(finalUser);

      // Clear check-in session for new login
      debugPrint('[AuthController] ═══════════════════════════════════════');
      debugPrint('[AuthController] Login successful - clearing check-in session');
      await SharedPreferencesService.clearCheckInSession();
      debugPrint('[AuthController] ═══════════════════════════════════════');

      // Trigger initial sync after login (mobile only)
      if (!kIsWeb) {
        _triggerInitialSync();
      }

      return finalUser;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Trigger initial sync in background (don't await)
  void _triggerInitialSync() {
    Future(() async {
      try {
        debugPrint('[AuthController] 🔄 Triggering initial sync...');
        final syncManager = SyncManager(_localDataSource, _remoteDataSource);
        await syncManager.sync();
        debugPrint('[AuthController] ✅ Initial sync completed');
      } catch (e) {
        debugPrint('[AuthController] ⚠️ Initial sync failed: $e');
      }
    });
  }

  Future<User> register(String email, String password, String name, String role) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(email, password, name, role);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      // Clear check-in session before logout
      debugPrint('[AuthController] ═══════════════════════════════════════');
      debugPrint('[AuthController] Logout - clearing check-in session');
      await SharedPreferencesService.clearCheckInSession();
      debugPrint('[AuthController] ═══════════════════════════════════════');

      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
