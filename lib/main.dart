import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'presentation/controllers/bootstrap_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: KinetixApp(),
    ),
  );
}

class KinetixApp extends ConsumerWidget {
  const KinetixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Bootstrap is watched to ensure initialization
    ref.watch(bootstrapControllerProvider);
    
    return MaterialApp.router(
      title: 'Kinetix',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
