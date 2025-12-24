import 'package:equatable/equatable.dart';
import 'package:hey_buddy/features/chat/domain/entities/user.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class HomePageConversationsInitial extends ChatState {}

class HomePageConversationsLoading extends ChatState {}

class HomePageConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  final bool isOffline;

  const HomePageConversationsLoaded({
    required this.conversations,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [conversations, isOffline];
}

class ChatPageConversationLoading extends ChatState {}

class ChatPageConversationLoadedLoaded extends ChatState {
  final List<Message> messages;

  const ChatPageConversationLoadedLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatPageConversationsError extends ChatState {
  final String message;
  final bool isOffline;

  const ChatPageConversationsError({
    required this.message,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [message, isOffline];
}

class HomaPageConversationsError extends ChatState {
  final String message;
  final bool isOffline;

  const HomaPageConversationsError({
    required this.message,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [message, isOffline];
}

class MessageSending extends ChatState {}

class MessageSent extends ChatState {
  final bool isPending;

  const MessageSent({this.isPending = false});

  @override
  List<Object?> get props => [ isPending];
}

class NewMessageReceived extends ChatState {
  final Message message;

  const NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class ChatError extends ChatState {
  final String message;
  final bool isOffline;

  const ChatError({required this.message, this.isOffline = false});

  @override
  List<Object?> get props => [message, isOffline];
}

class UsersInitial extends ChatState {}

class UsersLoading extends ChatState {}

class UsersLoaded extends ChatState {
  final List<User> users;
  const UsersLoaded(this.users);
}

class UsersError extends ChatState {
  final String message;
  UsersError(this.message);
}
