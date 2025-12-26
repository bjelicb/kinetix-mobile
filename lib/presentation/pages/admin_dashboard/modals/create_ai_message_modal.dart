import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import '../../../../domain/entities/ai_message.dart';
import '../../../controllers/admin_controller.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/gradient_card.dart';
import '../../../../core/utils/haptic_feedback.dart';

class CreateAIMessageModal extends ConsumerStatefulWidget {
  final List<User> clients;

  const CreateAIMessageModal({
    super.key,
    required this.clients,
  });

  @override
  ConsumerState<CreateAIMessageModal> createState() => _CreateAIMessageModalState();
}

class _CreateAIMessageModalState extends ConsumerState<CreateAIMessageModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  String? _selectedClientId;
  AIMessageTone? _selectedTone;
  AIMessageTrigger? _selectedTrigger;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _missedCountController = TextEditingController();
  final TextEditingController _streakController = TextEditingController();
  final TextEditingController _weightChangeController = TextEditingController();
  bool _isSending = false;
  String? _selectedTemplate;
  final GlobalKey _metadataInputKey = GlobalKey();

  // Template definitions
  final Map<AIMessageTrigger, List<Map<String, String>>> _templates = {
    AIMessageTrigger.missedWorkouts: [
      {'message': 'Propustio si {missedCount} treninga ove nedelje. Vrati se u ritam!', 'tone': 'WARNING'},
      {'message': '{missedCount} propuštena treninga? To nisu rezultati koje očekujemo.', 'tone': 'AGGRESSIVE'},
      {'message': 'Vreme je da se vratiš. {missedCount} treninga čeka.', 'tone': 'WARNING'},
    ],
    AIMessageTrigger.streak: [
      {'message': '{streak} dana uzastopno! Nastavi ovim tempom, šampione!', 'tone': 'MOTIVATIONAL'},
      {'message': 'Neverovatnih {streak} dana! Ovo je prava disciplina!', 'tone': 'MOTIVATIONAL'},
      {'message': '{streak} dana bez propuštanja - ti si mašina!', 'tone': 'MOTIVATIONAL'},
    ],
    AIMessageTrigger.weightSpike: [
      {'message': 'Težina ti je porasla {weightChange}kg ove nedelje. Hajde da razgovaramo.', 'tone': 'WARNING'},
      {'message': '+{weightChange}kg? Vreme je za objašnjenje šta se dešava.', 'tone': 'WARNING'},
      {'message': 'Značajna promena: +{weightChange}kg. Check-in potreban.', 'tone': 'WARNING'},
    ],
    AIMessageTrigger.sickDay: [
      {'message': 'Osećaš se bolesno? Prvo zdravlje. Oporavi se i vrati jači.', 'tone': 'EMPATHETIC'},
      {'message': 'Svako ima teške dane. Bitno je da se vratiš kada si spreman.', 'tone': 'EMPATHETIC'},
      {'message': 'Tvoje zdravlje dolazi prvo. Odmori se kako treba.', 'tone': 'EMPATHETIC'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    _missedCountController.dispose();
    _streakController.dispose();
    _weightChangeController.dispose();
    super.dispose();
  }

  Color _getToneColor(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.motivational:
        return AppColors.success;
      case AIMessageTone.warning:
        return AppColors.warning;
      case AIMessageTone.aggressive:
        return AppColors.error;
      case AIMessageTone.empathetic:
        return AppColors.info;
    }
  }

  IconData _getToneIcon(AIMessageTone tone) {
    switch (tone) {
      case AIMessageTone.aggressive:
        return Icons.warning_rounded;
      case AIMessageTone.empathetic:
        return Icons.favorite_rounded;
      case AIMessageTone.motivational:
        return Icons.trending_up_rounded;
      case AIMessageTone.warning:
        return Icons.info_rounded;
    }
  }

  AIMessageTone _toneFromString(String tone) {
    switch (tone.toUpperCase()) {
      case 'AGGRESSIVE':
        return AIMessageTone.aggressive;
      case 'EMPATHETIC':
        return AIMessageTone.empathetic;
      case 'MOTIVATIONAL':
        return AIMessageTone.motivational;
      case 'WARNING':
        return AIMessageTone.warning;
      default:
        return AIMessageTone.motivational;
    }
  }

  String _getTriggerLabel(AIMessageTrigger trigger) {
    switch (trigger) {
      case AIMessageTrigger.missedWorkouts:
        return 'Missed Workouts';
      case AIMessageTrigger.streak:
        return 'Streak';
      case AIMessageTrigger.weightSpike:
        return 'Weight Spike';
      case AIMessageTrigger.sickDay:
        return 'Sick Day';
    }
  }

  void _selectTemplate(AIMessageTrigger trigger, Map<String, String> template) {
    setState(() {
      _selectedTrigger = trigger;
      _selectedTone = _toneFromString(template['tone']!);
      _messageController.text = template['message']!;
      _selectedTemplate = '${trigger.toString()}_${template['message']}';
    });
    AppHaptic.selection();
    
    // Auto-scroll to metadata input field after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_metadataInputKey.currentContext != null) {
        Scrollable.ensureVisible(
          _metadataInputKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_messageController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message must be at least 10 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTrigger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trigger'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if tone is selected (required for both tabs)
    if (_selectedTone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tone'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Build metadata based on trigger
      Map<String, dynamic> metadata = {};
      if (_selectedTrigger == AIMessageTrigger.missedWorkouts) {
        final missedCount = int.tryParse(_missedCountController.text.trim());
        if (missedCount != null && missedCount > 0) {
          metadata['missedCount'] = missedCount;
        } else {
          // Check if message contains {missedCount} placeholder
          if (_messageController.text.contains('{missedCount}')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter the number of missed workouts'),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() => _isSending = false);
            return;
          }
        }
      } else if (_selectedTrigger == AIMessageTrigger.streak) {
        final streak = int.tryParse(_streakController.text.trim());
        if (streak != null && streak > 0) {
          metadata['streak'] = streak;
        } else {
          if (_messageController.text.contains('{streak}')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter the streak (number of days)'),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() => _isSending = false);
            return;
          }
        }
      } else if (_selectedTrigger == AIMessageTrigger.weightSpike) {
        final weightChange = double.tryParse(_weightChangeController.text.trim());
        if (weightChange != null) {
          metadata['weightChange'] = weightChange;
        } else {
          if (_messageController.text.contains('{weightChange}')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter the weight change (kg)'),
                backgroundColor: AppColors.error,
              ),
            );
            setState(() => _isSending = false);
            return;
          }
        }
      }

      debugPrint('[CreateAIMessageModal] Metadata before replacement: $metadata');
      debugPrint('[CreateAIMessageModal] Original message: ${_messageController.text}');

      // Replace variables in message (works for both Quick Templates and Custom Message)
      String finalMessage = _messageController.text;
      if (metadata.containsKey('missedCount')) {
        finalMessage = finalMessage.replaceAll('{missedCount}', metadata['missedCount'].toString());
      }
      if (metadata.containsKey('streak')) {
        finalMessage = finalMessage.replaceAll('{streak}', metadata['streak'].toString());
      }
      if (metadata.containsKey('weightChange')) {
        finalMessage = finalMessage.replaceAll('{weightChange}', metadata['weightChange'].toString());
      }

      debugPrint('[CreateAIMessageModal] Final message after replacement: $finalMessage');

      // Always send custom message and tone (both Quick Templates and Custom Message use frontend templates)
      // Quick Templates tab uses pre-defined templates from frontend (in Serbian)
      // Custom Message tab uses user-entered message
      await ref.read(adminControllerProvider.notifier).generateAIMessage(
            clientId: _selectedClientId!,
            trigger: _selectedTrigger!,
            customMessage: finalMessage,
            tone: _selectedTone,
            metadata: metadata.isNotEmpty ? metadata : null,
          );

      if (!mounted) return;
      
      // Close modal and return success result
      // Parent widget will show SnackBar and refresh the list
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      // Show error message in modal (user can still see it before closing)
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Return false to indicate error
      Navigator.pop(context, false);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create AI Message',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Client Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Client',
                prefixIcon: Icon(Icons.person_rounded),
                filled: true,
                fillColor: AppColors.surface1,
              ),
              // ignore: deprecated_member_use
              value: _selectedClientId,
              items: widget.clients.map((client) {
                // Use clientProfileId if available, otherwise fallback to userId
                final clientId = client.clientProfileId ?? client.id;
                return DropdownMenuItem(
                  value: clientId,
                  child: Text('${client.name} (${client.email})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedClientId = value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Quick Templates'),
              Tab(text: 'Custom Message'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTemplatesTab(),
                _buildCustomTab(),
              ],
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                NeonButton(
                  text: 'Send Message',
                  icon: Icons.send_rounded,
                  onPressed: _sendMessage,
                  isLoading: _isSending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a template',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          // Metadata inputs - shown at top when template is selected
          if (_selectedTrigger != null) ...[
            Container(
              key: _metadataInputKey,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Required Information',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_selectedTrigger == AIMessageTrigger.missedWorkouts)
                    TextField(
                      controller: _missedCountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Missed Count *',
                        hintText: 'Number of missed workouts',
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixIcon: const Icon(Icons.fitness_center_rounded),
                        suffixIcon: _missedCountController.text.isEmpty
                            ? const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                  else if (_selectedTrigger == AIMessageTrigger.streak)
                    TextField(
                      controller: _streakController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Streak (days) *',
                        hintText: 'Number of consecutive days',
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixIcon: const Icon(Icons.local_fire_department_rounded),
                        suffixIcon: _streakController.text.isEmpty
                            ? const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    )
                  else if (_selectedTrigger == AIMessageTrigger.weightSpike)
                    TextField(
                      controller: _weightChangeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Weight Change (kg) *',
                        hintText: 'Weight change in kilograms',
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixIcon: const Icon(Icons.monitor_weight_rounded),
                        suffixIcon: _weightChangeController.text.isEmpty
                            ? const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          ..._templates.entries.map((entry) {
            final trigger = entry.key;
            final templates = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTriggerLabel(trigger),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...templates.map((template) {
                  final tone = _toneFromString(template['tone']!);
                  final toneColor = _getToneColor(tone);
                  final toneIcon = _getToneIcon(tone);
                  final templateKey = '${trigger.toString()}_${template['message']}';
                  final isSelected = _selectedTemplate == templateKey;

                  return GestureDetector(
                    onTap: () => _selectTemplate(trigger, template),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: GradientCard(
                        gradient: LinearGradient(
                          colors: [
                            toneColor.withValues(alpha: 0.2),
                            toneColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderColor: isSelected ? toneColor : Colors.transparent,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(toneIcon, color: toneColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                template['message']!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tone picker
          DropdownButtonFormField<AIMessageTone>(
            decoration: const InputDecoration(
              labelText: 'Tone',
              filled: true,
              fillColor: AppColors.surface1,
            ),
            // ignore: deprecated_member_use
            value: _selectedTone,
            items: [
              DropdownMenuItem(
                value: AIMessageTone.motivational,
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text('Motivational'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: AIMessageTone.warning,
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: AppColors.warning),
                    const SizedBox(width: 8),
                    const Text('Warning'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: AIMessageTone.aggressive,
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Text('Aggressive'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: AIMessageTone.empathetic,
                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: AppColors.info),
                    const SizedBox(width: 8),
                    const Text('Empathetic'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedTone = value);
            },
          ),
          const SizedBox(height: 16),
          // Trigger picker
          DropdownButtonFormField<AIMessageTrigger>(
            decoration: const InputDecoration(
              labelText: 'Trigger',
              filled: true,
              fillColor: AppColors.surface1,
            ),
            // ignore: deprecated_member_use
            value: _selectedTrigger,
            items: [
              DropdownMenuItem(
                value: AIMessageTrigger.missedWorkouts,
                child: const Text('Missed Workouts'),
              ),
              DropdownMenuItem(
                value: AIMessageTrigger.streak,
                child: const Text('Streak Achievement'),
              ),
              DropdownMenuItem(
                value: AIMessageTrigger.weightSpike,
                child: const Text('Weight Spike'),
              ),
              DropdownMenuItem(
                value: AIMessageTrigger.sickDay,
                child: const Text('Sick Day'),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedTrigger = value);
            },
          ),
          const SizedBox(height: 16),
          // Custom message input
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Custom Message',
              hintText: 'Type your message here...',
              prefixIcon: Icon(Icons.message_rounded),
              filled: true,
              fillColor: AppColors.surface1,
            ),
            maxLines: 4,
            maxLength: 300,
          ),
          const SizedBox(height: 8),
          // Variable hints
          Text(
            'Available variables: {missedCount}, {streak}, {weightChange}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          // Metadata inputs
          if (_selectedTrigger == AIMessageTrigger.missedWorkouts)
            TextField(
              controller: _missedCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Missed Count',
                filled: true,
                fillColor: AppColors.surface1,
              ),
            )
          else if (_selectedTrigger == AIMessageTrigger.streak)
            TextField(
              controller: _streakController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Streak (days)',
                filled: true,
                fillColor: AppColors.surface1,
              ),
            )
          else if (_selectedTrigger == AIMessageTrigger.weightSpike)
            TextField(
              controller: _weightChangeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Weight Change (kg)',
                filled: true,
                fillColor: AppColors.surface1,
              ),
            ),
        ],
      ),
    );
  }
}

