import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/analytics_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/analytics/trainer_only_access_widget.dart';
import '../../presentation/widgets/analytics/client_selection_dropdown_widget.dart';
import '../../presentation/widgets/analytics/clients_tab_widget.dart';
import '../../presentation/widgets/analytics/overview_tab_widget.dart';
import '../../presentation/widgets/analytics/progress_tab_widget.dart';
import 'analytics/services/analytics_page_service.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClientId;
  ClientAnalytics? _clientAnalytics;
  bool _isLoadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadClientAnalytics(String clientId, String clientName) async {
    if (_selectedClientId == clientId && _clientAnalytics != null) return;

    setState(() {
      _isLoadingAnalytics = true;
      _selectedClientId = clientId;
    });

    final analytics = await AnalyticsPageService.loadClientAnalytics(ref, clientId, clientName);

    setState(() {
      _clientAnalytics = analytics;
      _isLoadingAnalytics = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final isTrainer = user?.role == 'TRAINER';

    // Only show for trainers
    if (!isTrainer) {
      return const TrainerOnlyAccessWidget();
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Clients'),
              Tab(text: 'Overview'),
              Tab(text: 'Progress'),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Client Selection Dropdown
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClientSelectionDropdownWidget(
                  selectedClientId: _selectedClientId,
                  onClientSelected: _loadClientAnalytics,
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ClientsTabWidget(
                      selectedClientId: _selectedClientId,
                      onClientSelected: _loadClientAnalytics,
                    ),
                    OverviewTabWidget(
                      analytics: _clientAnalytics,
                      isLoading: _isLoadingAnalytics,
                    ),
                    ProgressTabWidget(
                      analytics: _clientAnalytics,
                      isLoading: _isLoadingAnalytics,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
