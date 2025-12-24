import 'package:equatable/equatable.dart';
import '../../data/models/last_message_model.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final String type; // ai | user
  final String title;

  final String? userId;
  final List<String> participantIds;

  final List<Message> messages;

  final LastMessageModel? lastMessage;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.userId,
    required this.participantIds,
    required this.messages,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAIChat => type == 'ai';
  bool get isUserChat => type == 'user';

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    userId,
    participantIds,
    messages,
    lastMessage,
    createdAt,
    updatedAt,
  ];
}
