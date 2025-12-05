import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/checkin.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/models/checkin_collection.dart' if (dart.library.html) '../../data/models/checkin_collection_stub.dart';
import '../../data/mappers/checkin_mapper.dart';

part 'checkin_controller.g.dart';

@riverpod
class CheckInController extends _$CheckInController {
  late LocalDataSource _localDataSource;
  
  @override
  FutureOr<List<CheckIn>> build() async {
    _localDataSource = LocalDataSource();
    final collections = await _localDataSource.getAllCheckIns();
    return collections.map((c) => CheckInMapper.toEntity(c)).toList();
  }
  
  Future<void> deleteCheckIn(String id) async {
    final isarId = int.tryParse(id);
    if (isarId == null) throw Exception('Invalid check-in ID');
    
    await _localDataSource.deleteCheckIn(isarId);
    // Refresh check-ins
    state = AsyncValue.data(await _localDataSource.getAllCheckIns()
        .then((collections) => collections.map((c) => CheckInMapper.toEntity(c)).toList()));
  }
}

