import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/bootstrap.dart';

part 'bootstrap_controller.g.dart';

@riverpod
FutureOr<bool> bootstrapController(BootstrapControllerRef ref) async {
  await BootstrapService.initialize();
  return true;
}

