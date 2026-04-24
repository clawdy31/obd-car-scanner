import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth Service - Handles Bluetooth OBD adapter discovery and connection
/// Supports ELM327-compatible Bluetooth OBD-II adapters (HC-05, HC-06, Modaxe II, etc.)
class BluetoothService {
  Function(bool connected, String? error)? onConnectionStateChanged;
  Function(List<BluetoothDevice> devices)? onDevicesFound;
  Function(Uint8List data)? onDataReceived;
  Function(String message)? onStatusChanged;

  BluetoothConnection? _connection;
  StreamSubscription? _listenSubscription;
  bool _isConnected = false;
  bool _isScanning = false;

  BluetoothService();

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;

  /// Check if Bluetooth is available and enabled
  Future<({bool available, bool enabled})> checkBluetoothStatus() async {
    try {
      bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      return (available: isAvailable ?? false, enabled: isEnabled ?? false);
    } catch (e) {
      return (available: false, enabled: false);
    }
  }

  /// Request Bluetooth permissions (Android 12+ compatible)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Check Android version
      int sdkInt = await _getAndroidSdkInt();
      
      if (sdkInt >= 31) {
        // Android 12+ requires these permissions
        var scanStatus = await Permission.bluetoothScan.request();
        var connectStatus = await Permission.bluetoothConnect.request();
        
        if (scanStatus.isDenied || connectStatus.isDenied) {
          onStatusChanged?.call('Bluetooth permissions denied');
          return false;
        }
        if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
          onStatusChanged?.call('Open settings to enable Bluetooth permissions');
          return false;
        }
      }
      
      // Location permission for legacy scanning
      var locationStatus = await Permission.locationWhenInUse.request();
      if (locationStatus.isPermanentlyDenied) {
        onStatusChanged?.call('Location permission needed for Bluetooth scanning');
      }
    }
    return true;
  }

  Future<int> _getAndroidSdkInt() async {
    // Default to latest Android if can't determine
    return 31;
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      onStatusChanged?.call('Failed to get paired devices: $e');
      return [];
    }
  }

  /// Start scanning for nearby Bluetooth devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;

    _isScanning = true;
    onStatusChanged?.call('Scanning for Bluetooth devices...');

    try {
      // First get paired devices
      List<BluetoothDevice> paired = await getPairedDevices();
      onDevicesFound?.call(paired);

      // Then start discovery
      StreamSubscription? discoverySub;
      discoverySub = FlutterBluetoothSerial.instance.startDiscovery()
        .listen(
          (result) {
            BluetoothDevice device = result.device;
            List<BluetoothDevice> current = [...paired];
            
            // Add discovered device if not already in list
            if (!current.any((d) => d.address == device.address)) {
              current.add(device);
              onDevicesFound?.call(current);
            }
          },
          onError: (e) {
            _isScanning = false;
            onStatusChanged?.call('Scan error: $e');
          },
          onDone: () {
            _isScanning = false;
            onStatusChanged?.call('Scan complete');
          },
        );

      // Apply timeout
      await Future.delayed(timeout);
      await discoverySub.cancel();
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      _isScanning = false;
    } catch (e) {
      _isScanning = false;
      onStatusChanged?.call('Scan failed: $e');
    }
  }

  /// Connect to a Bluetooth device (OBD-II adapter)
  Future<bool> connect(BluetoothDevice device, {int timeoutSeconds = 10}) async {
    onStatusChanged?.call('Connecting to ${device.name ?? device.address}...');

    try {
      // Cancel any existing connection
      await disconnect();

      // Connect with timeout
      _connection = await BluetoothConnection.toAddress(device.address).timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      _isConnected = true;
      onConnectionStateChanged?.call(true, null);
      onStatusChanged?.call('Connected to ${device.name ?? 'OBD-II Adapter'}');

      // Start listening to data
      _startListening();

      return true;
    } catch (e) {
      _isConnected = false;
      String error = 'Connection failed: $e';
      onConnectionStateChanged?.call(false, error);
      onStatusChanged?.call(error);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        _connection!.dispose();
        _connection = null;
      } catch (e) {
        // Ignore disconnect errors
      }
    }

    _listenSubscription?.cancel();
    _listenSubscription = null;
    _isConnected = false;
    onConnectionStateChanged?.call(false, null);
  }

  /// Send data to connected device
  Future<void> send(String data) async {
    if (_connection == null || !_isConnected) return;

    try {
      _connection!.output.add(Uint8List.fromList(data.codeUnits));
      await _connection!.output.allSent;
    } catch (e) {
      onStatusChanged?.call('Send error: $e');
    }
  }

  /// Send command with carriage return (for ELM327)
  Future<String> sendCommand(String command, {int timeoutMs = 1000}) async {
    if (_connection == null || !_isConnected) {
      throw Exception('Not connected');
    }

    try {
      StringBuffer response = StringBuffer();
      Completer<String> completer = Completer();

      // Send command + CR
      _connection!.output.add(Uint8List.fromList('${command}\r'.codeUnits));
      await _connection!.output.allSent;

      // Listen for response with timeout
      StreamSubscription? sub;
      Timer? timer;

      sub = _connection!.input?.listen(
        (data) {
          String chunk = String.fromCharCodes(data);
          response.write(chunk);

          // Check for end of response (prompt '>' character)
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
            completer.completeError(e);
          }
        },
      );

      timer = Timer(Duration(milliseconds: timeoutMs), () {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(response.toString());
        }
      });

      return completer.future;
    } catch (e) {
      onStatusChanged?.call('Command error: $e');
      rethrow;
    }
  }

  void _startListening() {
    _listenSubscription?.cancel();

    _connection?.input?.listen(
      (data) {
        onDataReceived?.call(data);
      },
      onError: (e) {
        onStatusChanged?.call('Connection error: $e');
        disconnect();
      },
      onDone: () {
        disconnect();
      },
    );
  }

  /// Get device info for display
  String getDeviceInfo(BluetoothDevice device) {
    String name = device.name ?? 'Unknown Device';
    String address = device.address;
    String bonded = device.isBonded ? 'Paired' : 'Not Paired';
    return '$name ($address) - $bonded';
  }

  void dispose() {
    disconnect();
    _listenSubscription?.cancel();
  }
}

/// Extension to check if device might be an OBD adapter
extension BluetoothDeviceExtension on BluetoothDevice {
  bool get isObdAdapter {
    String name = this.name?.toLowerCase() ?? '';
    return name.contains('obd') ||
        name.contains('elm') ||
        name.contains('hc-0') ||
        name.contains('modaxe') ||
        name.contains('vgate') ||
        name.contains('toshiba');
  }
}
