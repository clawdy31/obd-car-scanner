import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as classic;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'models/obd_device.dart';

/// Unified Bluetooth Scanner - scans both Classic and BLE simultaneously
class BluetoothScannerManager {
  Function(List<ObdDevice> devices)? onDevicesFound;
  Function(String message)? onStatusChanged;
  Function(bool isScanning)? onScanStateChanged;

  final List<ObdDevice> _devices = [];
  StreamSubscription? _classicScanSub;
  StreamSubscription? _bleScanSub;
  bool _isScanning = false;

  BluetoothScannerManager();

  bool get isScanning => _isScanning;

  /// Check Bluetooth availability and permissions
  Future<({bool available, bool enabled, bool permissionsGranted})> checkStatus() async {
    bool available = false;
    bool enabled = false;
    bool permissionsGranted = true;

    try {
      if (Platform.isAndroid) {
        int sdkInt = 31; // Default to Android 12+
        
        if (sdkInt >= 31) {
          var scanStatus = await Permission.bluetoothScan.status;
          var connectStatus = await Permission.bluetoothConnect.status;
          
          permissionsGranted = scanStatus.isGranted && connectStatus.isGranted;
        }
        
        // Check Classic Bluetooth
        bool? classicAvail = await classic.FlutterBluetoothSerial.instance.isAvailable;
        bool? classicEnabled = await classic.FlutterBluetoothSerial.instance.isEnabled;
        available = classicAvail ?? false;
        enabled = classicEnabled ?? false;

        // Also check BLE
        if (!available) {
          available = await ble.FlutterBluePlus.isSupported;
        }
        if (!enabled) {
          // Check BLE adapter state
          final adapterState = await ble.FlutterBluePlus.adapterState.first;
          enabled = adapterState == ble.BluetoothAdapterState.on;
        }
      } else if (Platform.isIOS) {
        // iOS - only BLE is supported via flutter_blue_plus
        available = await ble.FlutterBluePlus.isSupported;
        if (available) {
          final adapterState = await ble.FlutterBluePlus.adapterState.first;
          enabled = adapterState == ble.BluetoothAdapterState.on;
        }
      }
    } catch (e) {
      onStatusChanged?.call('Error checking Bluetooth status: $e');
    }

    return (available: available, enabled: enabled, permissionsGranted: permissionsGranted);
  }

  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      int sdkInt = 31;
      
      if (sdkInt >= 31) {
        var scanResult = await Permission.bluetoothScan.request();
        var connectResult = await Permission.bluetoothConnect.request();
        
        if (scanResult.isDenied || connectResult.isDenied) {
          onStatusChanged?.call('Bluetooth permissions denied');
          return false;
        }
        
        if (scanResult.isPermanentlyDenied || connectResult.isPermanentlyDenied) {
          onStatusChanged?.call('Open app settings to enable Bluetooth permissions');
          return false;
        }
      }
      
      // Location permission for older Android versions
      var locationResult = await Permission.locationWhenInUse.request();
      if (locationResult.isPermanentlyDenied) {
        onStatusChanged?.call('Location permission may be needed for Bluetooth scanning');
      }
    }
    
    return true;
  }

  /// Start scanning for both Classic and BLE devices
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;

    _isScanning = true;
    _devices.clear();
    onScanStateChanged?.call(true);
    onStatusChanged?.call('Scanning for devices...');

    if (Platform.isIOS) {
      // iOS - only BLE scan supported
      await _startBleScan(timeout);
      await Future.delayed(timeout);
      await stopScan();
    } else {
      // Android - scan both Classic and BLE
      await Future.wait([
        _startClassicScan(timeout),
        _startBleScan(timeout),
      ]);
      await Future.delayed(timeout);
      await stopScan();
    }
    
    onStatusChanged?.call('Scan complete - ${_devices.length} devices found');
  }

  /// Start Classic Bluetooth scan
  Future<void> _startClassicScan(Duration timeout) async {
    try {
      // Get paired devices first
      List<classic.BluetoothDevice> paired = [];
      try {
        paired = await classic.FlutterBluetoothSerial.instance.getBondedDevices();
        for (var device in paired) {
          _addDevice(ObdDevice(
            id: device.address,
            name: device.name,
            type: BluetoothType.classic,
            isPaired: true,
          ));
        }
      } catch (e) {
        // Paired devices fetch failed, continue with discovery
      }

      // Start discovery
      _classicScanSub = classic.FlutterBluetoothSerial.instance.startDiscovery()
        .listen(
          (result) {
            _addDevice(ObdDevice(
              id: result.device.address,
              name: result.device.name,
              type: BluetoothType.classic,
              isPaired: result.device.isBonded,
            ));
          },
          onError: (e) {
            onStatusChanged?.call('Classic scan error: $e');
          },
          onDone: () {
            // Classic scan done
          },
        );

      // Apply timeout to classic scan
      Future.delayed(timeout, () {
        _classicScanSub?.cancel();
        _classicScanSub = null;
      });
    } catch (e) {
      onStatusChanged?.call('Failed to start classic scan: $e');
    }
  }

  /// Start BLE scan
  Future<void> _startBleScan(Duration timeout) async {
    try {
      // Check if BLE is supported
      if (!await ble.FlutterBluePlus.isSupported) {
        return;
      }

      // Ensure adapter is on
      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      if (adapterState != ble.BluetoothAdapterState.on) {
        return;
      }

      // Start BLE scan
      await ble.FlutterBluePlus.startScan(timeout: timeout);

      // Listen to scan results
      _bleScanSub = ble.FlutterBluePlus.scanResults.listen(
        (results) {
          for (var result in results) {
            // Avoid duplicates
            if (!_devices.any((d) => d.id == result.device.remoteId.str && d.type == BluetoothType.ble)) {
              _addDevice(ObdDevice(
                id: result.device.remoteId.str,
                name: result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'OBD-II Device',
                type: BluetoothType.ble,
                rssi: result.rssi,
              ));
            }
          }
        },
        onError: (e) {
          onStatusChanged?.call('BLE scan error: $e');
        },
      );
    } catch (e) {
      onStatusChanged?.call('Failed to start BLE scan: $e');
    }
  }

  /// Add device to list (avoiding duplicates)
  void _addDevice(ObdDevice device) {
    // Check if device already exists
    bool exists = _devices.any((d) => d.id == device.id && d.type == device.type);
    
    if (!exists) {
      _devices.add(device);
      onDevicesFound?.call(List.from(_devices));
    }
  }

  /// Stop all scans
  Future<void> stopScan() async {
    if (!_isScanning) return;

    _isScanning = false;

    try {
      _classicScanSub?.cancel();
      _classicScanSub = null;

      if (await ble.FlutterBluePlus.isScanningNow) {
        await ble.FlutterBluePlus.stopScan();
      }
      _bleScanSub?.cancel();
      _bleScanSub = null;
    } catch (e) {
      // Ignore errors during stop
    }

    onScanStateChanged?.call(false);
  }

  /// Get list of discovered devices
  List<ObdDevice> get devices => List.from(_devices);

  /// Filter devices to show only OBD adapters
  List<ObdDevice> get obdDevices => 
      _devices.where((d) => d.isObdAdapter).toList();

  /// Dispose of resources
  void dispose() {
    stopScan();
  }
}
