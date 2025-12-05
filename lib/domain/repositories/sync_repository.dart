abstract class SyncRepository {
  Future<void> sync();
  Future<void> pushChanges();
  Future<void> pullChanges();
}

