import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String content;
  final String? recipientId; // ADDED THIS

  const SendMessageEvent({
    required this.conversationId,
    required this.content,
    this.recipientId, // ADDED THIS
  });

  @override
  List<Object?> get props => [conversationId, content, recipientId];
}

class LoadConversationsEvent extends ChatEvent {}

class LoadConversationEvent extends ChatEvent {
  final String conversationId;

  const LoadConversationEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class ConnectWebSocketEvent extends ChatEvent {}

class DisconnectWebSocketEvent extends ChatEvent {}

class NewMessageReceivedEvent extends ChatEvent {
  final Message message;

  const NewMessageReceivedEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class LoadUsersEvent extends ChatEvent {}

class SearchUsersEvent extends ChatEvent {
  final String query;
  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}