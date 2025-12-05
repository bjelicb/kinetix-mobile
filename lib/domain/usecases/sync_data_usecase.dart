import '../repositories/sync_repository.dart';

class SyncDataUseCase {
  final SyncRepository _repository;
  
  SyncDataUseCase(this._repository);
  
  Future<void> call() async {
    await _repository.sync();
  }
}

