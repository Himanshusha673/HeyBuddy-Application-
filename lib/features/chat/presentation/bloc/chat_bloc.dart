import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/connectivity_manager.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/usecases/connect_websocket_usecase.dart';
import '../../domain/usecases/get_all_users_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/listen_to_messages_usecase.dart';
import '../../domain/usecases/search_user_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/join_room_usecase.dart';
import '../../domain/usecases/mark_message_delivered_usecase.dart';
import '../../domain/usecases/typing_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final ListenToMessagesUseCase listenToMessagesUseCase;
  final ConnectivityManager connectivityManager;
  final ConnectWebSocketUseCase connectWebSocketUseCase;
  final GetAllUsersUseCase getAllUsers;
  final SearchUsersUseCase searchUsers;
  final SecureStorage secureStorage;
  final JoinRoomUseCase joinRoomUseCase;
  final MarkMessageDeliveredUseCase markMessageDeliveredUseCase;
  final SendTypingUseCase sendTypingUseCase;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _connectivitySubscription;

  final Set<String> _sentMessageIds = {};
  String? _currentUserId;
  String? _currentPartnerId;

  ChatBloc({
    required this.sendMessageUseCase,
    required this.getConversationsUseCase,
    required this.getMessagesUseCase,
    required this.listenToMessagesUseCase,
    required this.connectivityManager,
    required this.connectWebSocketUseCase,
    required this.getAllUsers,
    required this.searchUsers,
    required this.secureStorage,
    required this.joinRoomUseCase,
    required this.markMessageDeliveredUseCase,
    required this.sendTypingUseCase,
  }) : super(HomePageConversationsInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<LoadConversationsEvent>(_onLoadConversations);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<ConnectWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    on<JoinRoomEvent>(_onJoinRoom);
    on<MessageStatusUpdateEvent>(_onMessageStatusUpdate);
    on<SendTypingEvent>(_onSendTyping);
    on<LoadUsersEvent>(_onLoadUsersEvent);
    on<SearchUsersEvent>(_onSearchUsersEvent);

    _initializeUser();

    _connectivitySubscription = connectivityManager.connectivityStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online &&
          state is HomePageConversationsLoaded) {
        //log('🔄 Connectivity restored, reloading conversations');
        add(LoadConversationsEvent());
      }
    });
  }

  Future<void> _initializeUser() async {
    _currentUserId = await secureStorage.getUserId();
    //log('👤 Current user ID initialized: $_currentUserId');
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await sendMessageUseCase(
        event.msg,
        recipientId: event.recipientId,
      );

      if (message.id.isNotEmpty) {
        _sentMessageIds.add(message.id);
        //log('✅ Message sent with ID: ${message.id}');

        Future.delayed(const Duration(seconds: 5), () {
          _sentMessageIds.remove(message.id);
        });
      }

      final isPending = !connectivityManager.isOnline;
      emit(MessageSent(isPending: isPending, msg: message));
    } catch (e, stackTrace) {
      //log('❌ Error sending message: $e', stackTrace: stackTrace);
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
    if (state is! HomePageConversationsLoading) {
      emit(HomePageConversationsLoading());
    }

    try {
      //log('🔄 Loading conversations...');
      final conversations = await getConversationsUseCase();
      //log("✅ Loaded ${conversations.length} conversations");

      emit(
        HomePageConversationsLoaded(
          conversations: conversations,
          isOffline: !connectivityManager.isOnline,
        ),
      );
    } catch (e, stackTrace) {
      //log('❌ Error loading conversations: $e', stackTrace: stackTrace);
      emit(
        HomaPageConversationsError(
          message: e.toString(),
          isOffline: !connectivityManager.isOnline,
        ),
      );
    }
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatPageConversationLoading());
    try {
      final userId = await secureStorage.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      //log('🔄 Loading messages: userId=$userId, partnerId=${event.partnerId}');

      final messages = await getMessagesUseCase(userId, event.partnerId);

      //log('✅ Loaded ${messages} messages');

      emit(ChatPageConversationLoadedLoaded(messages));
    } catch (e, stackTrace) {
      //log('❌ Error loading messages: $e', stackTrace: stackTrace);
      emit(ChatPageConversationsError(message: e.toString()));
    }
  }

  Future<void> _onConnectWebSocket(
    ConnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      //log('🔌 Connecting WebSocket...');
      await connectWebSocketUseCase();

      _messageSubscription = listenToMessagesUseCase().listen(
        (message) {
          if (!_sentMessageIds.contains(message.id)) {
            //log('📨 New message received in bloc: ${message.content}');
            add(NewMessageReceivedEvent(message: message));
            add(LoadConversationsEvent());
          } else {
            //log('⏭️ Skipping own message: ${message.id}');
          }
        },
        onError: (error) {
          //log('❌ WebSocket message stream error: $error');
        },
      );

      _statusSubscription = listenToMessagesUseCase.statusStream().listen(
        (statusData) {
          //log('📊 Status update received: $statusData');
          add(MessageStatusUpdateEvent(statusData: statusData));
        },
        onError: (error) {
          //log('❌ WebSocket status stream error: $error');
        },
      );

      _typingSubscription = listenToMessagesUseCase.typingStream().listen(
        (typingData) {
          //log('⌨️ Typing indicator received: $typingData');
          add(
            MessageStatusUpdateEvent(
              statusData: {
                'isTyping': typingData['isTyping'],
                'userId': typingData['userId'],
                'type': 'typing_indicator',
              },
            ),
          );
        },
        onError: (error) {
          //log('❌ WebSocket typing stream error: $error');
        },
      );

      //log('✅ WebSocket connected and all streams listening');
    } catch (e, stackTrace) {
      //log('❌ Failed to connect WebSocket: $e', stackTrace: stackTrace);
      emit(ChatError(message: 'Failed to connect WebSocket: $e'));
    }
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _messageSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _typingSubscription?.cancel();
    _messageSubscription = null;
    _statusSubscription = null;
    _typingSubscription = null;
    //log('🔌 WebSocket disconnected and streams cancelled');
  }

  void _onNewMessageReceived(
    NewMessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    //log('📩 Processing new message in state: ${event.message.content}');
    emit(NewMessageReceived(message: event.message));
  }

  Future<void> _onJoinRoom(JoinRoomEvent event, Emitter<ChatState> emit) async {
    try {
      final userId = await secureStorage.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _currentPartnerId = event.partnerId;
      joinRoomUseCase(userId, event.partnerId);
      //log('🚪 Joined room: $userId ↔️ ${event.partnerId}');
    } catch (e) {
      //log('❌ Error joining room: $e');
    }
  }

  void _onMessageStatusUpdate(
    MessageStatusUpdateEvent event,
    Emitter<ChatState> emit,
  ) {
    //log('📊 Message status update emitted: ${event.statusData}');

    // ALWAYS emit status updates, regardless of current page
    emit(MessageStatusUpdated(statusData: event.statusData));

    // Also reload conversations if on home page
    if (state is HomePageConversationsLoaded) {
      add(LoadConversationsEvent());
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) {
    if (_currentUserId == null || event.receiverId == null) {
      //log('⚠️ Cannot send typing: missing user IDs');
      return;
    }

    if (event.isTyping) {
      sendTypingUseCase.startTyping(_currentUserId!, event.receiverId!);
      //log('⌨️ Typing started');
    } else {
      sendTypingUseCase.endTyping(_currentUserId!, event.receiverId!);
      //log('⌨️ Typing ended');
    }
  }

  Future<void> _onLoadUsersEvent(
    LoadUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(UsersLoading());
    try {
      //log('🔄 Loading users...');
      final users = await getAllUsers();
      //log('✅ Loaded ${users.length} users');
      emit(UsersLoaded(users));
    } catch (e, stackTrace) {
      //log('❌ Error loading users: $e', stackTrace: stackTrace);
      emit(UsersError(e.toString()));
    }
  }

  Future<void> _onSearchUsersEvent(
    SearchUsersEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(UsersLoading());
    try {
      //log('🔍 Searching users with query: ${event.query}');
      final users = await searchUsers(event.query);
      //log('✅ Search found ${users.length} users');
      emit(UsersLoaded(users));
    } catch (e, stackTrace) {
      //log('❌ Error searching users: $e', stackTrace: stackTrace);
      emit(UsersError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _typingSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _sentMessageIds.clear();
    //log('🧹 ChatBloc closed and cleaned up');
    return super.close();
  }
}
