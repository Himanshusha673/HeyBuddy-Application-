import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class ConnectivityManager {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get connectivityStream => _connectivityController.stream;
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  ConnectivityStatus get currentStatus => _currentStatus;

  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  Future<void> initialize() async {
    // Check initial connectivity
    await _updateConnectivityStatus();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _updateConnectivityStatus();
    });
  }

  Future<void> _updateConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      final newStatus = result == ConnectivityResult.none
          ? ConnectivityStatus.offline
          : ConnectivityStatus.online;

      if (_currentStatus != newStatus) {
        _currentStatus = newStatus;
        _connectivityController.add(newStatus);
        
        AppLogger.log(
          'Connectivity changed: ${newStatus.name}',
          'Connectivity',
        );
      }
    } catch (e) {
      AppLogger.error('Error checking connectivity', e, StackTrace.current);
    }
  }

  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return isOnline;
  }

  void dispose() {
    _connectivityController.close();
  }
}

enum ConnectivityStatus {
  online,
  offline,
  unknown,
}