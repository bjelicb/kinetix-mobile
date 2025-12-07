import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/user.dart';
import '../controllers/auth_controller.dart';

part 'theme_controller.g.dart';

enum TrainerTheme { milan, aca, neutral }

@riverpod
class ThemeController extends _$ThemeController {
  @override
  TrainerTheme build() {
    final user = ref.watch(authControllerProvider).valueOrNull;
    return _determineTheme(user);
  }
  
  TrainerTheme _determineTheme(User? user) {
    if (user == null) return TrainerTheme.neutral;
    
    // Trainers see their own theme
    if (user.role == 'TRAINER') {
      if (user.name.toLowerCase().contains('milan')) {
        return TrainerTheme.milan;
      } else if (user.name.toLowerCase().contains('aca')) {
        return TrainerTheme.aca;
      }
    }
    
    // Clients see their assigned trainer's theme
    if (user.role == 'CLIENT' && user.trainerName != null) {
      if (user.trainerName!.toLowerCase().contains('milan')) {
        return TrainerTheme.milan;
      } else if (user.trainerName!.toLowerCase().contains('aca')) {
        return TrainerTheme.aca;
      }
    }
    
    return TrainerTheme.neutral;
  }
}
