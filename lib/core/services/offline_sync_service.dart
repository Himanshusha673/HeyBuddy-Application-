import 'dart:async';
import '../network/connectivity_manager.dart';
import '../storage/offline_storage.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../utils/logger.dart';

class OfflineSyncService {
  final OfflineStorage _offlineStorage;
  final ChatRemoteDataSource _chatRemoteDataSource;
  final ConnectivityManager _connectivityManager;

  StreamSubscription? _connectivitySubscription;

  OfflineSyncService({
    required OfflineStorage offlineStorage,
    required ChatRemoteDataSource chatRemoteDataSource,
    required ConnectivityManager connectivityManager,
  }) : _offlineStorage = offlineStorage,
       _chatRemoteDataSource = chatRemoteDataSource,
       _connectivityManager = connectivityManager;

  void startListening() {
    _connectivitySubscription = _connectivityManager.connectivityStream.listen((
      status,
    ) {
      if (status == ConnectivityStatus.online) {
        AppLogger.log('Back online - syncing pending messages', 'Sync');
        syncPendingMessages();
      }
    });
  }

  Future<void> syncPendingMessages() async {
    try {
      final pendingMessages = await _offlineStorage.getPendingMessages();

      if (pendingMessages.isEmpty) {
        AppLogger.log('No pending messages to sync', 'Sync');
        return;
      }

      AppLogger.log(
        'Syncing ${pendingMessages.length} pending messages',
        'Sync',
      );

      for (final message in pendingMessages) {
        try {
          await _chatRemoteDataSource.sendMessage(
            message['conversationId'],
            message['content'],
            message['recipientId'],
          );

          await _offlineStorage.removePendingMessage(message);
          AppLogger.log('Synced message successfully', 'Sync');
        } catch (e) {
          AppLogger.error('Failed to sync message', e, StackTrace.current);
          // Keep the message in pending queue
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sync pending messages', e, stackTrace);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
