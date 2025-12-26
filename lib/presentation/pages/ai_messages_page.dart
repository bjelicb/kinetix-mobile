import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import '../../data/datasources/remote_data_source.dart';
import '../widgets/gradient_background.dart';
import '../widgets/ai_message_card.dart';
import '../widgets/shimmer_loader.dart';
import '../controllers/common_providers.dart';
import '../controllers/auth_controller.dart';

class AIMessagesPage extends ConsumerStatefulWidget {
  const AIMessagesPage({super.key});

  @override
  ConsumerState<AIMessagesPage> createState() => _AIMessagesPageState();
}

class _AIMessagesPageState extends ConsumerState<AIMessagesPage> {
  List<AIMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    debugPrint('[AIMessages:Fetch] Loading messages for client');
    
    try {
      // Get current user from auth controller (works on both mobile and web)
      final user = ref.read(authControllerProvider).valueOrNull;
      
      if (user == null) {
        debugPrint('[AIMessages:Fetch] ⚠ No user found in auth controller');
        _messages = [];
        return;
      }
      
      final userId = user.id;
      debugPrint('[AIMessages:Fetch] User ID from auth controller: $userId');
      debugPrint('[AIMessages:Fetch] User role: ${user.role}');
      
      // Load messages from API
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      // Get clientProfileId (not userId!)
      debugPrint('[AIMessages:Fetch] Fetching client profile to get clientProfileId...');
      final clientProfile = await remoteDataSource.getClientProfile(userId);
      final clientProfileId = clientProfile['_id'] as String;
      debugPrint('[AIMessages:Fetch] Client Profile ID: $clientProfileId');
      
      final messagesData = await remoteDataSource.getAIMessages(clientProfileId);
      _messages = messagesData.map((data) => AIMessage.fromJson(data)).toList();
      
      // Sort by created date (newest first)
      _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('[AIMessages:Display] ✓ Loaded ${_messages.length} messages');
      
    } catch (e) {
      debugPrint('[AIMessages:Fetch] ✗ Error loading messages: $e');
      _messages = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String messageId) async {
    debugPrint('[AIMessages:MarkRead] Marking message $messageId as read');
    
    // Optimistic update
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
      }
    });
    
    try {
      // Mark message as read via API
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      await remoteDataSource.markAIMessageAsRead(messageId);
      debugPrint('[AIMessages:MarkRead] ✓ Message marked as read');
      
    } catch (e) {
      debugPrint('[AIMessages:MarkRead] ✗ Error marking message as read: $e');
      
      // Rollback on error
      setState(() {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isRead: false);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark message as read'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  int get _unreadCount {
    final count = _messages.where((m) => !m.isRead).length;
    debugPrint('[AIMessages:Badge] Unread count: $count');
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const Text('AI Messages'),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: Colors.transparent,
        ),
        body: _isLoading
            ? const Center(child: ShimmerLoader(width: 300, height: 120))
            : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Messages Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI coach will send you personalized messages based on your performance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return AIMessageCard(
          message: message,
          onTap: () {
            if (!message.isRead) {
              _markAsRead(message.id);
            }
          },
        );
      },
    );
  }
}

