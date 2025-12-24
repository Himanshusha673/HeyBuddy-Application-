// ============================================
// lib/features/chat/presentation/bloc/chat_bloc.dart (FIXED)
// ============================================
import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/connectivity_manager.dart';
import '../../domain/usecases/connect_websocket_usecase.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_conversation_by_id_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/listen_to_messages_usecase.dart';
import '../../domain/usecases/search_user_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final ListenToMessagesUseCase listenToMessagesUseCase;
  final ConnectivityManager connectivityManager;
  final ConnectWebSocketUseCase connectWebSocketUseCase;
  final GetAllUsersUseCase getAllUsers;
  final SearchUsersUseCase searchUsers;
  final GetConversationByIdUseCase getConversationByIdUseCase;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectivitySubscription;

  final Set<String> _sentMessageIds = {};

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getConversationsUseCase,
    required this.listenToMessagesUseCase,
    required this.connectivityManager,
    required this.connectWebSocketUseCase,
    required this.getAllUsers,
    required this.searchUsers,
    required this.getConversationByIdUseCase,
  }) : super(HomePageConversationsInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<LoadConversationsEvent>(_onLoadConversations);
    on<ConnectWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    on<LoadUsersEvent>(_onLoadUsersEvent);
    on<SearchUsersEvent>(_onSearchUsersEvent);
    on<LoadConversationEvent>(_onLoadConversationByConversationId);

    _connectivitySubscription = connectivityManager.connectivityStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online &&
          state is HomePageConversationsLoaded) {
        add(LoadConversationsEvent());
      }
    });
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(MessageSending());
    try {
      log(
        'Sending message: conversationId=${event.conversationId}, recipientId=${event.recipientId}',
      );

      final message = await sendMessageUseCase(
        event.conversationId,
        event.content,
        recipientId: event.recipientId,
      );

      if (message.id.isNotEmpty) {
        _sentMessageIds.add(message.id);
        Future.delayed(const Duration(seconds: 5), () {
          _sentMessageIds.remove(message.id);
        });
      }

      final isPending = !connectivityManager.isOnline;

      log('Message sent successfully: ${message.id}');

      emit(MessageSent(isPending: isPending));
    } catch (e, stackTrace) {
      log('Error sending message: $e', stackTrace: stackTrace);
      emit(
        ChatError(
          message: e.toString(),
          isOffline: !connectivityManager.isOnline,
        ),
      );
    }
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(HomePageConversationsLoading());
    try {
      final conversations = await getConversationsUseCase();
      log("Loaded ${conversations.length} conversations");

      emit(
        HomePageConversationsLoaded(
          conversations: conversations,
          isOffline: !connectivityManager.isOnline,
        ),
      );
    } catch (e, stackTrace) {
      log('Error loading conversations: $e', stackTrace: stackTrace);
      emit(
        HomaPageConversationsError(
          message: e.toString(),
          isOffline: !connectivityManager.isOnline,
        ),
      );
    }
  }

  Future<void> _onLoadConversationByConversationId(
    LoadConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatPageConversationLoading());
    try {
      log('Loading conversation: ${event.conversationId}');

      final messages = await getConversationByIdUseCase(event.conversationId);

      log('Loaded ${messages.length} messages');

      emit(ChatPageConversationLoadedLoaded(messages));
    } catch (e, stackTrace) {
      log('Error loading conversation: $e', stackTrace: stackTrace);
      emit(ChatPageConversationsError(message: e.toString()));
    }
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await connectWebSocketUseCase();

      _messageSubscription = listenToMessagesUseCase().listen(
        (message) {
          if (!_sentMessageIds.contains(message.id)) {
            add(NewMessageReceivedEvent(message: message));
          }
        },
        onError: (error) {
          log('WebSocket stream error: $error');
        },
      );

      log('WebSocket connected and listening');
    } catch (e, stackTrace) {
      log('Failed to connect WebSocket: $e', stackTrace: stackTrace);
      emit(ChatError(message: 'Failed to connect WebSocket: $e'));
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    log('WebSocket disconnected');
  }

  void _onNewMessageReceived(
    NewMessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    log('New message received: ${event.message.content}');
    emit(NewMessageReceived(message: event.message));
  }

  Future<void> _onLoadUsersEvent(
    LoadUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final users = await getAllUsers();
      log('Loaded ${users.length} users');
      emit(UsersLoaded(users));
    } catch (e, stackTrace) {
      log('Error loading users: $e', stackTrace: stackTrace);
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onSearchUsersEvent(
    SearchUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final users = await searchUsers(event.query);
      log('Search found ${users.length} users');
      emit(UsersLoaded(users));
    } catch (e, stackTrace) {
      log('Error searching users: $e', stackTrace: stackTrace);
      emit(UsersError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _sentMessageIds.clear();
    return super.close();
  }
}
