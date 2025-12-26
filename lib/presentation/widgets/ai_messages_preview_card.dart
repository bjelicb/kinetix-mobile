import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/ai_message.dart';
import '../../data/datasources/remote_data_source.dart';
import '../controllers/common_providers.dart';
import '../controllers/auth_controller.dart';
import 'gradient_card.dart';
import 'shimmer_loader.dart';

/// Widget that displays a preview of latest AI messages on dashboard
class AIMessagesPreviewCard extends ConsumerStatefulWidget {
  const AIMessagesPreviewCard({super.key});

  @override
  ConsumerState<AIMessagesPreviewCard> createState() => _AIMessagesPreviewCardState();
}

class _AIMessagesPreviewCardState extends ConsumerState<AIMessagesPreviewCard> {
  List<AIMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    // Prevent multiple simultaneous loads
    if (_isLoading) {
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Get current user from auth controller (works on both mobile and web)
      final user = ref.read(authControllerProvider).valueOrNull;
      
      if (user == null) {
        _messages = [];
        return;
      }
      
      final userId = user.id;
      
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      // Get clientProfileId (not userId!)
      final clientProfile = await remoteDataSource.getClientProfile(userId);
      final clientProfileId = clientProfile['_id'] as String;
      
      final messagesData = await remoteDataSource.getAIMessages(clientProfileId);
      
      _messages = messagesData.map((data) => AIMessage.fromJson(data)).toList();
      
      // Sort by created date (newest first) and take only latest 3
      _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (_messages.length > 3) {
        _messages = _messages.sublist(0, 3);
      }
      
    } catch (e) {
      debugPrint('[AIMessagesPreview] ❌ ERROR loading messages: $e');
      _messages = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _unreadCount {
    return _messages.where((m) => !m.isRead).length;
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

  @override
  Widget build(BuildContext context) {
    debugPrint('[AIMessagesPreview] build() - isLoading: $_isLoading, messages count: ${_messages.length}');
    
    if (_isLoading) {
      debugPrint('[AIMessagesPreview] Showing loading state');
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const ShimmerLoader(
          height: 120,
          width: double.infinity,
          borderRadius: 16,
        ),
      );
    }

    if (_messages.isEmpty) {
      debugPrint('[AIMessagesPreview] No messages, returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    debugPrint('[AIMessagesPreview] Rendering card with ${_messages.length} messages');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GradientCard(
        padding: const EdgeInsets.all(16),
        pressEffect: true,
        onTap: () async {
          // Navigate to messages page and refresh when returning
          await context.push('/ai-messages');
          // Refresh messages after returning from messages page
          if (mounted) {
            _loadMessages();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Messages',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Latest message preview
            ..._messages.take(1).map((message) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getToneColor(message.tone).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getToneColor(message.tone).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getToneColor(message.tone),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            message.tone.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!message.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_messages.length > 1) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${_messages.length - 1} more message${_messages.length - 1 > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

