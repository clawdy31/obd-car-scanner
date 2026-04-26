// iOS stub - Classic Bluetooth not supported on iOS
import 'dart:async';
import 'obd_connection.dart';

/// Classic Bluetooth (SPP) - iOS stub
/// iOS blocks Classic Bluetooth (SPP). This stub ensures the import doesn't crash on iOS.
class ClassicObdConnection implements ObdConnection {
  final _dataStreamController = StreamController<String>.broadcast();
  final _stateStreamController = StreamController<ConnectionState>.broadcast();
  final _currentState = ConnectionState.disconnected;

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Stream<ConnectionState> get stateStream => _stateStreamController.stream;

  @override
  ConnectionState get currentState => _currentState;

  @override
  bool get isConnected => false;

  @override
  Future<bool> connect(String deviceId) async {
    _dataStreamController.addError(UnimplementedError('Classic Bluetooth not supported on iOS'));
    return false;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> write(String data) async {}

  Stream<String> get data => dataStream;

  @override
  Future<String> writeWithResponse(String data, {Duration? timeout}) async => '';

  @override
  void dispose() {
    _dataStreamController.close();
    _stateStreamController.close();
  }
}