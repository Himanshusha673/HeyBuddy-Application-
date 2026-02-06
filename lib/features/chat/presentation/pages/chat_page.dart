import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hey_buddy/core/storage/secure_storage.dart';
import 'package:hey_buddy/features/chat/data/models/message_model.dart';
import 'package:hey_buddy/features/chat/presentation/widgets/chat_input.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String? recipientId;
  final String? recipientName;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.recipientId,
    this.recipientName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late ChatBloc _chatBloc;
  double _keyboardHeight = 0;
  bool _keyboardVisible = false;
  final Uuid uuid = Uuid();

  final FocusNode _focusNode = FocusNode();

  final ValueNotifier<List<Message>> _messages = ValueNotifier([]);

  // Add this ValueNotifier for AI thinking indicator
  final ValueNotifier<bool> _isAIThinking = ValueNotifier(false);

  // Track pending messages by content to replace with real message

  Timer? _typingTimer;

  bool _isRecipientOnline = false;
  String? _lastSeen;

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    log(
      'ChatPage initState: conversationId=${widget.conversationId}, recipientId=${widget.recipientId}',
    );

    _chatBloc = context.read<ChatBloc>();

    // Check if it's AI chat
    final isAIChat =
        widget.recipientId == "ai-bot" || widget.recipientId == "ai_assistance";

    if (isAIChat) {
      // For AI chat, set online status immediately
      _isRecipientOnline = true;
      _lastSeen = null;
    }

    WidgetsBinding.instance.addObserver(this);

    _isRecipientOnline = false;
    _lastSeen = null;
    _isTyping = false;

    _focusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChanged);

    if (widget.recipientId != null) {
      _chatBloc.add(
        JoinRoomEvent(partnerId: widget.recipientId ?? "ai_assistance"),
      );
      _chatBloc.add(
        LoadMessagesEvent(partnerId: widget.recipientId ?? 'ai_assistance'),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _textController.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    _focusNode.dispose();
    _scrollController.dispose();
    _textController.dispose();
    // Dispose ValueNotifier
    _isAIThinking.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.recipientId == null) return;

    final text = _textController.text;

    if (text.isNotEmpty) {
      _chatBloc.add(
        SendTypingEvent(receiverId: widget.recipientId, isTyping: true),
      );

      _typingTimer?.cancel();

      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatBloc.add(
          SendTypingEvent(receiverId: widget.recipientId, isTyping: false),
        );
      });
    } else {
      _chatBloc.add(
        SendTypingEvent(receiverId: widget.recipientId, isTyping: false),
      );
      _typingTimer?.cancel();
    }
  }

  void _onSendMessage() async {
    final content = _textController.text.trim();

    if (content.isEmpty) return;
    final userId = await SecureStorage().getUserId();

    final msgId = 'msg_${uuid.v4()}';

    // Create a temporary message to show immediately
    final tempMessage = MessageModel(
      id: msgId,
      content: content,
      senderId: userId,
      receiverId: widget.recipientId,
      timestamp: DateTime.now(),
      status:
          ((widget.recipientId == "ai-bot") ||
                  widget.recipientId == "ai_assistance")
              ? 'read'
              : 'sending',
      role: MessageRole.user,
      isMine: true,
    );

    _messages.value.add(tempMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    _textController.clear();

    if (widget.recipientId != null) {
      _chatBloc.add(
        SendTypingEvent(receiverId: widget.recipientId, isTyping: false),
      );
    }

    // Check if it's AI chat and show thinking indicator
    final isAIChat =
        widget.recipientId == "ai-bot" || widget.recipientId == "ai_assistance";

    if (isAIChat) {
      _isAIThinking.value = true;
    }

    // Send via bloc
    _chatBloc.add(
      SendMessageEvent(msg: tempMessage, recipientId: widget.recipientId),
    );
  }

  @override
  void didChangeMetrics() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;

    if (keyboardHeight > 0 && _keyboardHeight != keyboardHeight) {
      _keyboardHeight = keyboardHeight;
      _keyboardVisible = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } else if (keyboardHeight == 0 && _keyboardVisible) {
      _keyboardVisible = false;
      _keyboardHeight = 0;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom({bool instant = false}) {
    if (_scrollController.hasClients) {
      final duration =
          instant ? Duration.zero : const Duration(milliseconds: 300);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: duration,
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessageList(List<Message> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isAIThinking,
      builder: (context, isAIThinking, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: _keyboardVisible ? _keyboardHeight + 20 : 20,
          ),
          itemCount:
              messages.length + (_isTyping ? 1 : 0) + (isAIThinking ? 1 : 0),
          itemBuilder: (context, index) {
            // Handle AI thinking indicator
            if (isAIThinking &&
                index == messages.length + (_isTyping ? 1 : 0)) {
              return _buildAIThinkingIndicator();
            }

            // Handle typing indicator
            if (!isAIThinking && _isTyping && index == messages.length) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: TypingIndicator(),
              );
            }

            // Handle regular messages
            final adjustedIndex =
                isAIThinking && index >= messages.length + (_isTyping ? 1 : 0)
                    ? index - 1
                    : index;

            final message = messages[adjustedIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: MessageBubble(message: message),
            );
          },
        );
      },
    );
  }

  Widget _buildAIThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(
              20,
            ).copyWith(bottomLeft: const Radius.circular(4)),
            border: Border.all(color: AppColors.borderPrimary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thinking...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: _keyboardVisible ? _keyboardHeight + 20 : 20,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentBlue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.recipientId != null
                      ? Icons.person
                      : Icons.auto_awesome,
                  size: 64,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.recipientId != null
                    ? 'Say hi to ${widget.recipientName}!'
                    : 'Hello! I\'m HeyBuddy AI',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.recipientId != null
                    ? 'Send your first message to start the conversation'
                    : 'Ask me anything and I\'ll help you with it',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                      icon: Icons.lightbulb_outline,
                      label: 'Ideas',
                      onTap: () {
                        _textController.text =
                            'Can you help me brainstorm some ideas?';
                        _focusNode.requestFocus();
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.help_outline,
                      label: 'Help',
                      onTap: () {
                        _textController.text = 'I need help with something...';
                        _focusNode.requestFocus();
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.chat_outlined,
                      label: 'Chat',
                      onTap: () {
                        _textController.text = 'Let\'s have a conversation!';
                        _focusNode.requestFocus();
                      },
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

  void _updateMessageStatusById(String messageId, String status) {
    for (int i = 0; i < _messages.value.length; i++) {
      if (_messages.value[i].id == messageId) {
        _messages.value[i] = _messages.value[i].copyWith(status: status);
        // log('✅ Message status updated: $messageId -> $status');
        return;
      }
    }
  }

  void _updateTempMessageStatus(String tempId, String status) {
    for (int i = 0; i < _messages.value.length; i++) {
      if (_messages.value[i].id == tempId) {
        _messages.value[i] = _messages.value[i].copyWith(status: status);
        // log('✅ Temp message status updated: $tempId -> $status');
        return;
      }
    }
  }

  void _handleNewMessage(Message message) {
    final index = _messages.value.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final currentMessage = _messages.value[index];
      final newMessage = message.copyWith(status: currentMessage.status);
      _messages.value[index] = newMessage;
    } else {
      _messages.value.add(message);

      // Check if this is an AI response and hide thinking indicator
      final isAIChat =
          widget.recipientId == "ai-bot" ||
          widget.recipientId == "ai_assistance";

      if (isAIChat && message.role == MessageRole.assistant) {
        _isAIThinking.value = false;
      }
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderPrimary.withOpacity(0.2),
              ),
            ),
            child: Icon(icon, color: AppColors.accentBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (widget.recipientId == null) {
      return 'Always here to help';
    }

    if (_isTyping) {
      return 'typing...';
    }

    if (_isRecipientOnline) {
      return 'Online';
    }

    if (_lastSeen != null && _lastSeen!.isNotEmpty) {
      try {
        DateTime lastSeenDate;
        if (_lastSeen!.contains('T')) {
          lastSeenDate = DateTime.parse(_lastSeen!);
        } else {
          lastSeenDate = DateTime.fromMillisecondsSinceEpoch(
            int.parse(_lastSeen!),
            isUtc: false,
          );
        }

        final now = DateTime.now();
        final difference = now.difference(lastSeenDate);

        if (difference.inSeconds < 60) {
          return 'Last seen just now';
        } else if (difference.inMinutes < 60) {
          return 'Last seen ${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          return 'Last seen ${difference.inHours}h ago';
        } else if (difference.inDays < 7) {
          return 'Last seen ${difference.inDays}d ago';
        } else {
          return 'Last seen on ${lastSeenDate.day}/${lastSeenDate.month}/${lastSeenDate.year}';
        }
      } catch (e) {
        // log('Error parsing last seen: $e, value: $_lastSeen');
        return 'Offline';
      }
    }

    return 'Offline';
  }

  Color _getStatusColor() {
    if (widget.recipientId == null) {
      return AppColors.accentBlue;
    }

    if (_isTyping) {
      return AppColors.accentBlue;
    }

    if (_isRecipientOnline) {
      return AppColors.success;
    }

    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName ?? 'HeyBuddy AI',
              style: AppTextStyles.headlineSmall,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _getStatusText(),
              style: AppTextStyles.bodySmall.copyWith(
                color: _getStatusColor(),
                fontStyle: _isTyping ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessageSent) {
                  if (widget.recipientId == "ai-bot" ||
                      widget.recipientId == "ai_assistance") {
                    final messageIndex = _messages.value.indexWhere(
                      (m) => m.id == state.msg.id,
                    );

                    if (messageIndex != -1) {
                      final updatedMessages = [..._messages.value];
                      updatedMessages[messageIndex] =
                          updatedMessages[messageIndex].copyWith(
                            status: 'read',
                          );
                      _messages.value = updatedMessages;

                      log('✅ Message marked as sent: ${state.msg.id}');
                    }
                  } else {
                    final messageIndex = _messages.value.indexWhere(
                      (m) => m.id == state.msg.id,
                    );

                    if (messageIndex != -1) {
                      final updatedMessages = [..._messages.value];
                      updatedMessages[messageIndex] =
                          updatedMessages[messageIndex].copyWith(
                            status: 'sent',
                          );
                      _messages.value = updatedMessages;

                      log('✅ Message marked as sent: ${state.msg.id}');
                    }
                  }

                  if (state.isPending) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Message will be sent when online',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.cardColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                          left: 16,
                          right: 16,
                        ),
                      ),
                    );
                  }
                }

                if (state is NewMessageReceived) {
                  log('📩 New message received: ${state.message.id}');
                  _handleNewMessage(state.message);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom(instant: true);
                  });
                }

                if (state is ChatPageConversationLoadedLoaded) {
                  _messages.value = state.messages;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                if (state is MessageStatusUpdated) {
                  final statusData = state.statusData;
                  // log('🔄 Received status update: $statusData');

                  // Handle user status updates (online/offline)
                  if (statusData['type'] == 'user_status' &&
                      statusData['userId'] == widget.recipientId) {
                    setState(() {
                      _isRecipientOnline = statusData['status'] == 'online';
                      if (!_isRecipientOnline &&
                          statusData['lastSeen'] != null) {
                        _lastSeen = statusData['lastSeen']?.toString();
                        _isTyping = false;
                      }
                    });
                    // log(
                    //   '👤 User status updated: ${statusData['status']}, lastSeen: $_lastSeen',
                    // );
                  }
                  // Handle typing indicators
                  else if (statusData.containsKey('isTyping') &&
                      statusData['userId'] == widget.recipientId) {
                    setState(() {
                      _isTyping = statusData['isTyping'] ?? false;
                    });
                    if (_isTyping) {
                      _scrollToBottom();
                    }
                    // log('⌨️ Typing indicator: $_isTyping');
                  }
                  // Handle message delivery status with ID matching
                  else if (statusData.containsKey('messageId')) {
                    final messageId = statusData['messageId']?.toString();
                    final status = statusData['status']?.toString();
                    // final senderId = statusData['senderId']?.toString();
                    // final receiverId = statusData['receiverId']?.toString();

                    if (messageId != null && status != null) {
                      // log('📨 Updating message status: $messageId -> $status');

                      // Also check for pending messages by content
                      if (messageId.contains('temp_')) {
                        // Handle temp message status
                        _updateTempMessageStatus(messageId, status);
                      } else {
                        // Update real message status
                        _updateMessageStatusById(messageId, status);
                      }
                    }
                  }
                }

                if (state is ChatPageConversationsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        left: 16,
                        right: 16,
                      ),
                    ),
                  );

                  // Hide AI thinking indicator on error
                  final isAIChat =
                      widget.recipientId == "ai-bot" ||
                      widget.recipientId == "ai_assistance";
                  if (isAIChat) {
                    _isAIThinking.value = false;
                  }
                }
              },
              builder: (context, state) {
                if (state is ChatPageConversationLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.accentBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading conversation...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessageList(_messages.value);
              },
            ),
          ),
          ModernInputBar(
            controller: _textController,
            focusNode: _focusNode,
            onSend: _onSendMessage,
          ),
        ],
      ),
    );
  }
}
