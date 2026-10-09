import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../storage/hive_storage.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
  bool get isSimulatingOffline;
  Future<void> setSimulateOffline(bool value);
}

class NetworkInfoImpl extends ChangeNotifier implements NetworkInfo {
  final Connectivity _connectivity;
  final HiveStorageService _storage;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkInfoImpl({
    Connectivity? connectivity,
    HiveStorageService? storage,
  })  : _connectivity = connectivity ?? Connectivity(),
        _storage = storage ?? HiveStorageService() {
    _initListener();
  }

  void _initListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final connected = await isConnected;
      _connectivityController.add(connected);
      notifyListeners();
    });
  }

  @override
  bool get isSimulatingOffline => _storage.getSimulateOffline();

  @override
  Future<void> setSimulateOffline(bool value) async {
    await _storage.setSimulateOffline(value);
    final connected = await isConnected;
    _connectivityController.add(connected);
    notifyListeners();
  }

  @override
  Future<bool> get isConnected async {
    if (isSimulatingOffline) {
      return false;
    }
    final results = await _connectivity.checkConnectivity();
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  @override
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    super.dispose();
  }
}
