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

  /// Connect to a Classic Bluetooth device
  @override
  Future<bool> connect(String deviceId) async {
    if (_currentState == ConnectionState.connecting) {
      return false;
    }

    _updateState(ConnectionState.connecting);

    try {
      // Disconnect existing connection
      await disconnect();

      // Connect to device
      _connection = await BluetoothConnection.toAddress(deviceId).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw ObdConnectionException('Connection timed out', deviceId: deviceId),
      );

      _updateState(ConnectionState.connected);

      // Start listening for data
      _startListening();

      return true;
    } catch (e) {
      _updateState(ConnectionState.error);
      _dataStreamController.addError('Connection failed: $e');
      return false;
    }
  }

  /// Disconnect from device
  @override
  Future<void> disconnect() async {
    if (_currentState == ConnectionState.disconnected) {
      return;
    }

    _updateState(ConnectionState.disconnecting);

    try {
      _listenSubscription?.cancel();
      _listenSubscription = null;

      if (_connection != null) {
        await _connection!.close();
        _connection!.dispose();
        _connection = null;
      }
    } catch (e) {
      // Ignore errors during disconnect
    }

    _updateState(ConnectionState.disconnected);
  }

  /// Write command to ELM327 (auto-appends \r)
  @override
  Future<void> write(String command) async {
    if (_connection == null || !isConnected) {
      throw ObdConnectionException('Not connected');
    }

    try {
      // Auto-append carriage return
      String commandWithCR = command.endsWith('\r') ? command : '$command\r';
      _connection!.output.add(Uint8List.fromList(commandWithCR.codeUnits));
      await _connection!.output.allSent;
    } catch (e) {
      throw ObdConnectionException('Write failed: $e');
    }
  }

  /// Write command and wait for response
  @override
  Future<String> writeWithResponse(String command, {Duration timeout = const Duration(seconds: 2)}) async {
    if (_connection == null || !isConnected) {
      throw ObdConnectionException('Not connected');
    }

    StringBuffer response = StringBuffer();
    Completer<String> completer = Completer();
    StreamSubscription? sub;
    Timer? timer;

    try {
      // Send command with CR
      await write(command);

      sub = _connection!.input?.listen(
        (data) {
          String chunk = utf8.decode(data, allowMalformed: true);
          response.write(chunk);

          // ELM327 ends response with '>' prompt
          if (chunk.contains('>')) {
            timer?.cancel();
            sub?.cancel();
            if (!completer.isCompleted) {
              completer.complete(response.toString());
            }
          }
        },
        onError: (e) {
          timer?.cancel();
          sub?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(ObdConnectionException('Read error: $e'));
          }
        },
      );

      timer = Timer(timeout, () {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(response.toString());
        }
      });

      return await completer.future;
    } catch (e) {
      timer?.cancel();
      sub?.cancel();
      rethrow;
    }
  }

  void _startListening() {
    _listenSubscription?.cancel();

    _connection?.input?.listen(
      (data) {
        String text = utf8.decode(data, allowMalformed: true);
        _dataStreamController.add(text);
      },
      onError: (e) {
        _dataStreamController.addError(e);
        disconnect();
      },
      onDone: () {
        disconnect();
      },
    );
  }

  void _updateState(ConnectionState newState) {
    _currentState = newState;
    _stateStreamController.add(newState);
  }

  @override
  void dispose() {
    disconnect();
    _dataStreamController.close();
    _stateStreamController.close();
  }
}
