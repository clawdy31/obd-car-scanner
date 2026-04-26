// Real Classic Bluetooth implementation for Android
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'obd_connection.dart';

/// Classic Bluetooth (SPP) implementation of ObdConnection
/// Supports HC-05, HC-06, OBDLink SX, and other SPP-based adapters
class ClassicObdConnection implements ObdConnection {
  BluetoothConnection? _connection;
  final _dataStreamController = StreamController<String>.broadcast();
  final _stateStreamController = StreamController<ConnectionState>.broadcast();
  ConnectionState _currentState = ConnectionState.disconnected;
  StreamSubscription? _listenSubscription;

  @override
  Stream<String> get dataStream => _dataStreamController.stream;

  @override
  Stream<ConnectionState> get stateStream => _stateStreamController.stream;

  @override
  ConnectionState get currentState => _currentState;

  @override
  bool get isConnected => _currentState == ConnectionState.connected;

  @override
  Future<bool> connect(String deviceId) async {
    if (_currentState == ConnectionState.connecting) return false;
    _updateState(ConnectionState.connecting);

    try {
      await disconnect();
      _connection = await BluetoothConnection.toAddress(deviceId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw ObdConnectionException('Connection timed out', deviceId: deviceId),
      );

      _updateState(ConnectionState.connected);
      _startListening();

      return true;
    } catch (e) {
      _updateState(ConnectionState.disconnected);
      _dataStreamController.addError(e);
      return false;
    }
  }

  void _startListening() {
    if (_connection == null) return;
    final input = _connection!.input;
    if (input == null) return;
    _listenSubscription = input.listen(
      (data) {
        String decoded = utf8.decode(data, allowMalformed: true);
        _dataStreamController.add(decoded);
      },
      onDone: () => _updateState(ConnectionState.disconnected),
      onError: (e) {
        _updateState(ConnectionState.disconnected);
        _dataStreamController.addError(e);
      },
    );
  }

  @override
  Future<void> disconnect() async {
    await _listenSubscription?.cancel();
    _listenSubscription = null;
    await _connection?.close();
    _connection = null;
    _updateState(ConnectionState.disconnected);
  }

  @override
  Future<void> write(String data) async {
    if (_connection == null || _currentState != ConnectionState.connected) return;
    List<int> bytes = utf8.encode(data);
    _connection!.output.add(Uint8List.fromList(bytes));
    await _connection!.output.allSent;
  }

  Stream<String> get data => dataStream;

  @override
  Future<String> writeWithResponse(String data, {Duration? timeout}) async {
    await write(data);
    await Future.delayed(const Duration(milliseconds: 100));

    String response = '';
    await for (var chunk in dataStream) {
      response += chunk;
      if (chunk.contains('>')) break;
    }
    return response;
  }

  @override
  void dispose() {
    disconnect();
    _dataStreamController.close();
    _stateStreamController.close();
  }

  void _updateState(ConnectionState state) {
    _currentState = state;
    _stateStreamController.add(state);
  }
}
