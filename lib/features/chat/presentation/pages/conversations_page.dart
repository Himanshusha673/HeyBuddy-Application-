import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hey_buddy/core/storage/secure_storage.dart';
import 'package:hey_buddy/features/auth/presentation/pages/login_page.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../../../shared/widgets/connectivity_banner.dart';
import '../../../../shared/widgets/offline_indicator.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/conversation_tile.dart';
import 'chat_page.dart';
import 'users_chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadConversationsEvent());
    context.read<ChatBloc>().add(ConnectWebSocketEvent());
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.bgColor,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSecondary),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Text('Conversations', style: AppTextStyles.headlineSmall),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textSecondary),
              onPressed: () {
                SecureStorage().clearAll().then((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                buildWhen:
                    (previous, current) =>
                        current is HomePageConversationsInitial ||
                        current is HomePageConversationsLoading ||
                        current is HomePageConversationsLoaded ||
                        current is HomaPageConversationsError,
                builder: (context, state) {
                  log("state is ${state.toString()}");
                  if (state is HomePageConversationsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentBlue,
                        ),
                      ),
                    );
                  }

                  if (state is HomaPageConversationsError) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderSecondary),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (state.isOffline
                                        ? AppColors.warning
                                        : AppColors.error)
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                state.isOffline
                                    ? Icons.wifi_off
                                    : Icons.error_outline,
                                size: 48,
                                color:
                                    state.isOffline
                                        ? AppColors.warning
                                        : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              state.isOffline
                                  ? 'No Internet Connection'
                                  : 'Failed to load conversations',
                              style: AppTextStyles.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<ChatBloc>().add(
                                    LoadConversationsEvent(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  'Retry',
                                  style: AppTextStyles.button,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is HomePageConversationsLoaded) {
                    // TEMPORARY: Show all conversations without filtering
                    log(
                      '📱 Displaying ${state.conversations.length} conversations',
                    );

                    if (state.conversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderSecondary,
                                ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.textPrimary.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No conversations yet',
                              style: AppTextStyles.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a new chat to begin',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ChatBloc>().add(LoadConversationsEvent());
                      },
                      color: AppColors.accentBlue,
                      backgroundColor: AppColors.cardColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = state.conversations[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.borderSecondary,
                              ),
                            ),
                            child: ConversationTile(
                              conversation: conversation,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChatPage(
                                          conversationId: conversation.id,
                                          recipientId: conversation.userId,
                                          recipientName: conversation.username,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentBlue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              _showNewChatOptions(context);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            label: Text(
              'New Chat',
              style: AppTextStyles.button.copyWith(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Start New Chat', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 24),
                _NewChatOption(
                  icon: Icons.auto_awesome,
                  title: 'Chat with AI',
                  subtitle: 'Start a conversation with HeyBuddy AI',
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => const ChatPage(
                              conversationId: 'ai-bot',
                              recipientId: 'ai-bot',
                              recipientName: 'HeyBuddy AI',
                            ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                _NewChatOption(
                  icon: Icons.person_add,
                  title: 'Chat with User',
                  subtitle: 'Message another user',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserSearch()),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    context.read<ChatBloc>().add(DisconnectWebSocketEvent());
    super.dispose();
  }
}

class _NewChatOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NewChatOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSecondary),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
