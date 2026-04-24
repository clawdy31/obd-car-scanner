import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'obd_connection.dart';

/// BLE (Bluetooth Low Energy) implementation of ObdConnection
/// Supports BLE ELM327 dongles that use standard GATT services
class BleObdConnection implements ObdConnection {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  final _dataStreamController = StreamController<String>.broadcast();
  final _stateStreamController = StreamController<ConnectionState>.broadcast();
  ConnectionState _currentState = ConnectionState.disconnected;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _connectionSubscription;
  String? _lastDeviceId;
  List<int>? _lastValue;

  // Common BLE OBD service and characteristic UUIDs
  // Many BLE ELM327 adapters use these standard UUIDs
  static final List<Guid> _obdServiceUuids = [
    Guid('0000ffe0-0000-1000-8000-00805f9b34fb'), // Common OBD service
    Guid('0000fff0-0000-1000-8000-00805f9b34fb'), // Alternative OBD service
    Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e'), // Nordic UART Service
  ];

  static final List<Guid> _writeCharUuids = [
    Guid('0000ffe1-0000-1000-8000-00805f9b34fb'), // Common write char
    Guid('0000fff1-0000-1000-8000-00805f9b34fb'), // Alternative write
    Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e'), // Nordic UART TX
  ];

  static final List<Guid> _notifyCharUuids = [
    Guid('0000ffe3-0000-1000-8000-00805f9b34fb'), // Common notify char
    Guid('0000fff3-0000-1000-8000-00805f9b34fb'), // Alternative notify
    Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e'), // Nordic UART RX
  ];

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
    if (_currentState == ConnectionState.connecting) {
      return false;
    }

    _updateState(ConnectionState.connecting);
    _lastDeviceId = deviceId;

    try {
      // Stop any existing scan
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      // Get device from the MAC address
      _device = BluetoothDevice.fromId(deviceId);

      // Connect with timeout
      await _device!.connect(timeout: const Duration(seconds: 15));

      // Listen for connection state changes
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          disconnect();
        }
      });

      // Discover services and find OBD characteristics
      bool found = await _discoverAndSetupCharacteristics();

      if (!found) {
        await disconnect();
        throw ObdConnectionException('OBD characteristics not found on device', deviceId: deviceId);
      }

      _updateState(ConnectionState.connected);

      // Start listening for notifications
      _startNotifications();

      return true;
    } catch (e) {
      _updateState(ConnectionState.error);
      _dataStreamController.addError('BLE Connection failed: $e');
      return false;
    }
  }

  Future<bool> _discoverAndSetupCharacteristics() async {
    if (_device == null) return false;

    try {
      // Discover all services
      List<BluetoothService> services = await _device!.discoverServices();

      for (var service in services) {
        // Get characteristics
        for (var char in service.characteristics) {
          String charUuid = char.uuid.str.toLowerCase();

          // Find write characteristic
          if (_writeChar == null) {
            bool isWriteUuid = _writeCharUuids.any((uuid) => 
              charUuid == uuid.str.toLowerCase());
            bool isWritable = char.properties.write || char.properties.writeWithoutResponse;
            
            if (isWriteUuid || (isWritable && _notifyChar == null)) {
              _writeChar = char;
            }
          }

          // Find notify/read characteristic
          if (_notifyChar == null) {
            bool isNotifyUuid = _notifyCharUuids.any((uuid) => 
              charUuid == uuid.str.toLowerCase());
            bool isNotifiable = char.properties.notify || char.properties.indicate || char.properties.read;
            
            if (isNotifyUuid || isNotifiable) {
              _notifyChar = char;
            }
          }

          // If we found both, we're done
          if (_writeChar != null && _notifyChar != null) {
            return true;
          }
        }
      }

      // Fallback: try to use first writable and first notifiable characteristics
      for (var service in services) {
        for (var char in service.characteristics) {
          if (_writeChar == null && (char.properties.write || char.properties.writeWithoutResponse)) {
            _writeChar = char;
          }
          if (_notifyChar == null && (char.properties.notify || char.properties.indicate || char.properties.read)) {
            _notifyChar = char;
          }
        }
      }

      return _writeChar != null && _notifyChar != null;
    } catch (e) {
      _dataStreamController.addError('Service discovery failed: $e');
      return false;
    }
  }

  void _startNotifications() async {
    if (_notifyChar == null) return;

    try {
      // Determine if we should use notifications or read
      bool useNotify = _notifyChar!.properties.notify || _notifyChar!.properties.indicate;
      
      if (useNotify) {
        // Enable notifications
        await _notifyChar!.setNotifyValue(true);
        
        // Subscribe to value changes via lastValueStream
        _notifySubscription = _notifyChar!.lastValueStream.listen(
          (data) {
            _lastValue = data;
            if (data.isNotEmpty) {
              String text = utf8.decode(data, allowMalformed: true);
              _dataStreamController.add(text);
            }
          },
          onError: (e) {
            _dataStreamController.addError(e);
          },
          onDone: () {
            disconnect();
          },
        );
      }
    } catch (e) {
      _dataStreamController.addError('Notification setup failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    if (_currentState == ConnectionState.disconnected) {
      return;
    }

    _updateState(ConnectionState.disconnecting);

    try {
      _notifySubscription?.cancel();
      _notifySubscription = null;

      _connectionSubscription?.cancel();
      _connectionSubscription = null;

      _writeChar = null;
      _notifyChar = null;

      if (_device != null) {
        await _device!.disconnect();
        _device = null;
      }
    } catch (e) {
      // Ignore errors during disconnect
    }

    _updateState(ConnectionState.disconnected);
  }

  @override
  Future<void> write(String command) async {
    if (_writeChar == null || !isConnected) {
      throw ObdConnectionException('Not connected');
    }

    try {
      // Auto-append carriage return
      String commandWithCR = command.endsWith('\r') ? command : '$command\r';
      List<int> data = utf8.encode(commandWithCR);

      // Write with or without response depending on characteristic properties
      if (_writeChar!.properties.writeWithoutResponse) {
        await _writeChar!.write(data, withoutResponse: true);
      } else {
        await _writeChar!.write(data);
      }
    } catch (e) {
      throw ObdConnectionException('Write failed: $e');
    }
  }

  @override
  Future<String> writeWithResponse(String command, {Duration timeout = const Duration(seconds: 2)}) async {
    if (_writeChar == null || !isConnected) {
      throw ObdConnectionException('Not connected');
    }

    StringBuffer response = StringBuffer();
    Completer<String> completer = Completer();

    // Send command
    await write(command);

    // Listen for response via notifications
    StreamSubscription? sub;
    Timer? timer;

    sub = _dataStreamController.stream.listen(
      (data) {
        response.write(data);

        // Check for prompt indicating end of response
        if (data.contains('>')) {
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
