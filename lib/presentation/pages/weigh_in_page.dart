import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class WeighInPage extends StatefulWidget {
  const WeighInPage({super.key});

  @override
  State<WeighInPage> createState() => _WeighInPageState();
}

class _WeighInPageState extends State<WeighInPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isMonday = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _checkIfMonday();
    _loadLatestWeighIn();
  }

  void _checkIfMonday() {
    final now = DateTime.now();
    setState(() {
      _isMonday = now.weekday == DateTime.monday; // Monday is 1
    });
  }

  Future<void> _loadLatestWeighIn() async {
    setState(() {
      _processing = true;
    });
    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      final latest = await remoteDataSource.getLatestWeighIn();
      setState(() {
        if (latest != null) {
          _weightController.text = latest['weight'].toString();
          _notesController.text = latest['notes'] ?? '';
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading latest weigh-in: $e')),
        );
      }
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> _submitWeighIn() async {
    AppHaptic.medium();
    if (_weightController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your weight.')),
        );
      }
      return;
    }

    final double? weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight.')),
        );
      }
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);

      await remoteDataSource.createWeighIn(
        weight: weight,
        date: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weigh-in recorded successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Return true to indicate successful weigh-in, so dashboard can refresh
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record weigh-in: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Weekly Weigh-in'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            AppHaptic.medium();
            await _loadLatestWeighIn();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monday Recommendation (not blocking)
                  if (_isMonday)
                    GradientCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_rounded, color: AppColors.warning),
                        title: Text(
                          'Recommended: Monday Weigh-in',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.warning),
                        ),
                        subtitle: Text(
                          'Recording your weight on Monday (plan start day) helps track weekly progress accurately.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    GradientCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                        title: Text(
                          'Recommended: Record on Monday',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        subtitle: Text(
                          'Monday is the recommended day for weigh-ins (plan start day), but you can record on any day.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  
                  // Weight Input Card
                  GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Your Weight',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'e.g., 75.5',
                            prefixIcon: const Icon(Icons.scale_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.surface1,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Any comments on your weight change?',
                            prefixIcon: const Icon(Icons.notes_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.surface1,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        NeonButton(
                          text: 'Submit Weigh-in',
                          icon: Icons.check_circle_rounded,
                          onPressed: !_processing ? _submitWeighIn : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

