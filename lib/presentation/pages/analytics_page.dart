import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/analytics_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/strength_progression_chart.dart';
import '../../presentation/widgets/adherence_chart.dart';
import '../../presentation/widgets/shimmer_loader.dart';

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
    
    try {
      final controller = ref.read(analyticsControllerProvider.notifier);
      final analytics = await controller.getClientAnalytics(clientId, clientName);
      setState(() {
        _clientAnalytics = analytics;
        _isLoadingAnalytics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
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
          ),
          body: const Center(
            child: Text(
              'Analytics is only available for trainers.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final clientsState = ref.watch(analyticsControllerProvider);
                    
                    return clientsState.when(
                      data: (clients) {
                        if (clients.isEmpty) {
                          return GradientCard(
                            gradient: AppGradients.card,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No clients found',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        
                        // Auto-select first client if none selected
                        if (_selectedClientId == null && clients.isNotEmpty) {
                          final firstClient = clients.first;
                          final clientId = firstClient['_id']?.toString() ?? firstClient['id']?.toString() ?? '';
                          final clientName = firstClient['name']?.toString() ?? 
                                           '${firstClient['firstName'] ?? ''} ${firstClient['lastName'] ?? ''}'.trim();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadClientAnalytics(clientId, clientName);
                          });
                        }
                        
                        final clientMap = <String, String>{};
                        for (final client in clients) {
                          final id = client['_id']?.toString() ?? client['id']?.toString() ?? '';
                          final name = client['name']?.toString() ?? 
                                     '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim();
                          if (id.isNotEmpty && name.isNotEmpty) {
                            clientMap[id] = name;
                          }
                        }
                        
                        return GradientCard(
                          gradient: AppGradients.card,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: DropdownButton<String>(
                            value: _selectedClientId,
                            isExpanded: true,
                            underline: Container(),
                            dropdownColor: AppColors.surface,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            items: clientMap.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null && clientMap.containsKey(value)) {
                                _loadClientAnalytics(value, clientMap[value]!);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      loading: () => const ShimmerCard(height: 60),
                      error: (error, stack) => GradientCard(
                        gradient: AppGradients.card,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading clients: $error',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClientsTab(context),
                    _buildOverviewTab(context),
                    _buildProgressTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientsTab(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final clientsState = ref.watch(analyticsControllerProvider);
        
        return clientsState.when(
          data: (clients) {
            if (clients.isEmpty) {
              return Center(
                child: Text(
                  'No clients available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            
            return ListView(
              padding: const EdgeInsets.all(20),
              children: clients.map((client) {
                final clientId = client['_id']?.toString() ?? client['id']?.toString() ?? '';
                final clientName = client['name']?.toString() ?? 
                                 '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim();
                
                if (clientId.isEmpty || clientName.isEmpty) return const SizedBox.shrink();
                
                return GradientCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  gradient: AppGradients.card,
                  onTap: () {
                    _loadClientAnalytics(clientId, clientName);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            clientName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'View progress and statistics',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (_selectedClientId == clientId)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(3, (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 80),
            )),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading clients: $error',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    if (_isLoadingAnalytics || _clientAnalytics == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ShimmerCard(height: 250),
          const SizedBox(height: 32),
          const ShimmerCard(height: 100),
        ],
      );
    }
    
    final analytics = _clientAnalytics!;
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Weekly Adherence',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AdherenceChart(
          adherenceData: analytics.weeklyAdherence,
          isLoading: _isLoadingAnalytics,
        ),
        const SizedBox(height: 32),
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GradientCard(
                gradient: AppGradients.primary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${analytics.overallAdherence.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adherence',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientCard(
                gradient: AppGradients.secondary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${analytics.totalWorkouts}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Workouts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressTab(BuildContext context) {
    if (_isLoadingAnalytics || _clientAnalytics == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ShimmerCard(height: 300),
        ],
      );
    }
    
    final analytics = _clientAnalytics!;
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Strength Progression',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StrengthProgressionChart(
          exerciseData: analytics.strengthProgression,
          isLoading: _isLoadingAnalytics,
        ),
      ],
    );
  }
}

