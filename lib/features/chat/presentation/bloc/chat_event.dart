import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final Message msg;
  final String? recipientId;

  const SendMessageEvent({
    required this.msg,
    this.recipientId,
  });

  @override
  List<Object?> get props => [msg, recipientId];
}

class LoadConversationsEvent extends ChatEvent {}

class LoadMessagesEvent extends ChatEvent {
  final String partnerId;

  const LoadMessagesEvent({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class ConnectWebSocketEvent extends ChatEvent {}

class DisconnectWebSocketEvent extends ChatEvent {}

class JoinRoomEvent extends ChatEvent {
  final String partnerId;

  const JoinRoomEvent({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}

class NewMessageReceivedEvent extends ChatEvent {
  final Message message;

  const NewMessageReceivedEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageStatusUpdateEvent extends ChatEvent {
  final Map<String, dynamic> statusData;

  const MessageStatusUpdateEvent({required this.statusData});

  @override
  List<Object?> get props => [statusData];
}

class SendTypingEvent extends ChatEvent {
  final String? receiverId;
  final bool isTyping;

  const SendTypingEvent({
    required this.receiverId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [receiverId, isTyping];
}

class LoadUsersEvent extends ChatEvent {}

class SearchUsersEvent extends ChatEvent {
  final String query;
  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}