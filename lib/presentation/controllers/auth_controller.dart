import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/local_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late AuthRepository _repository;
  
  @override
  FutureOr<User?> build() async {
    final storage = FlutterSecureStorage();
    final localDataSource = LocalDataSource();
    // Use mock - backend not ready
    _repository = AuthRepositoryImpl(localDataSource, storage);
    
    return await _repository.getCurrentUser();
  }
  
  Future<User> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
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
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

