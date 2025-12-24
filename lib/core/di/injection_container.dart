import 'package:get_it/get_it.dart';
import 'package:hey_buddy/features/chat/domain/usecases/connect_websocket_usecase.dart';
import 'package:hey_buddy/features/chat/domain/usecases/get_all_users_usecase.dart';
import 'package:hey_buddy/features/chat/domain/usecases/get_conversation_by_id_usecase.dart';
import 'package:hey_buddy/features/chat/domain/usecases/search_user_usecase.dart';
import 'package:http/http.dart' as http;
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/send_message_usecase.dart';
import '../../features/chat/domain/usecases/get_conversations_usecase.dart';
import '../../features/chat/domain/usecases/listen_to_messages_usecase.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../network/api_client.dart';
import '../network/connectivity_manager.dart';
import '../network/websocket_client.dart';
import '../services/offline_sync_service.dart';
import '../storage/offline_storage.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============ Initialize Core Services ============
  final offlineStorage = OfflineStorage();
  await offlineStorage.initialize();
  sl.registerLazySingleton(() => offlineStorage);

  final connectivityManager = ConnectivityManager();
  await connectivityManager.initialize();
  sl.registerLazySingleton(() => connectivityManager);

  // ============ Bloc ============
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registerUseCase: sl()));

  sl.registerFactory(
    () => ChatBloc(
      sendMessageUseCase: sl(),
      getConversationsUseCase: sl(),
      listenToMessagesUseCase: sl(),
      connectivityManager: sl(),
      connectWebSocketUseCase: sl(),
      getAllUsers: sl(),
      searchUsers: sl(),
      getConversationByIdUseCase: sl(),
    ),
  );

  // ============ Use Cases ============
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => ListenToMessagesUseCase(sl()));
  sl.registerLazySingleton(() => ConnectWebSocketUseCase(sl()));
  sl.registerLazySingleton(() => GetAllUsersUseCase(sl()));
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));

  sl.registerLazySingleton(() => GetConversationByIdUseCase(sl()));
  // ============ Repositories ============
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      remoteDataSource: sl(),
      offlineStorage: sl(),
      connectivityManager: sl(),
    ),
  );

  // ============ Data Sources ============
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(apiClient: sl(), webSocketClient: sl()),
  );

  // ============ Services ============
  sl.registerLazySingleton(
    () => OfflineSyncService(
      offlineStorage: sl(),
      chatRemoteDataSource: sl(),
      connectivityManager: sl(),
    ),
  );

  // ============ Core ============
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => WebSocketClient());
  sl.registerLazySingleton(() => SecureStorage());
  sl.registerLazySingleton(() => http.Client());
}
