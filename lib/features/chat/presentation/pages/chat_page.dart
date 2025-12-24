import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme/app_colors.dart';
import '../../../../core/config/theme/app_text_styles.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../widgets/message_bubble.dart';

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

  // Focus node to detect keyboard visibility
  final FocusNode _focusNode = FocusNode();

  // Store messages locally
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    WidgetsBinding.instance.addObserver(this);

    // Add focus listener for keyboard
    _focusNode.addListener(_onFocusChange);

    // Initial scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(instant: true);
    });

    // Load conversation if ID is provided
    if (widget.conversationId.isNotEmpty) {
      _chatBloc.add(
        LoadConversationEvent(conversationId: widget.conversationId),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final keyboardHeight = viewInsets.bottom;

    if (keyboardHeight > 0 && _keyboardHeight != keyboardHeight) {
      _keyboardHeight = keyboardHeight;
      _keyboardVisible = true;
      // Scroll to bottom when keyboard appears
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
      // Keyboard will show
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

  void _onSendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    _chatBloc.add(
      SendMessageEvent(
        conversationId: widget.conversationId,
        content: content,
        recipientId: widget.recipientId,
      ),
    );

    _textController.clear();
    _focusNode.unfocus(); // Hide keyboard after sending
  }

  Widget _buildMessageList(List<Message> messages) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: _keyboardVisible ? _keyboardHeight + 20 : 20,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: MessageBubble(message: message),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.borderPrimary.withOpacity(0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient:
                    widget.recipientId != null
                        ? null
                        : AppColors.primaryGradient,
                color: widget.recipientId != null ? AppColors.cardColor : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderPrimary.withOpacity(0.2),
                ),
              ),
              child: Icon(
                widget.recipientId != null ? Icons.person : Icons.auto_awesome,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName ?? 'HeyBuddy AI',
                    style: AppTextStyles.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.recipientId != null
                        ? 'Online'
                        : 'Always here to help',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderPrimary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.video_call_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderPrimary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.phone_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderPrimary.withOpacity(0.2),
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessageSent) {
                  _scrollToBottom();
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
                  // Add new message to local list and scroll to bottom
                  _messages.add(state.message);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                if (state is ChatPageConversationLoadedLoaded) {
                  // Update messages when conversation is loaded
                  _messages = state.messages;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                if (state is ChatPageConversationsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
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
                }
              },
              builder: (context, state) {
                if (state is ChatPageConversationLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
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

                // For other states, show messages from local list
                return _buildMessageList(_messages);
              },
            ),
          ),
          _ModernInputBar(
            controller: _textController,
            focusNode: _focusNode,
            onSend: _onSendMessage,
          ),
        ],
      ),
    );
  }
}

class _ModernInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;

  const _ModernInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        border: Border(
          top: BorderSide(
            color: AppColors.borderPrimary.withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline,
            onPressed: () {},
            isActive: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderPrimary.withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textQuaternary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (previous, current) => current is MessageSent,
            builder: (context, state) {
              final isSending = state is MessageSent && state.isPending;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child:
                    isSending
                        ? Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                        : _buildActionButton(
                          icon: Icons.send_rounded,
                          onPressed: onSend,
                          isActive: controller.text.trim().isNotEmpty,
                        ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive ? null : AppColors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderPrimary.withOpacity(0.2)),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
