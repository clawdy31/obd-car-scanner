import 'dart:async';
import 'dart:io';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as classic;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:permission_handler/permission_handler.dart';
import 'models/obd_device.dart';

/// Unified Bluetooth Scanner - scans both Classic and BLE simultaneously (Android)
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

  Future<({bool available, bool enabled, bool permissionsGranted})> checkStatus() async {
    bool available = false;
    bool enabled = false;
    bool permissionsGranted = true;

    try {
      if (Platform.isAndroid) {
        int sdkInt = 31;

        if (sdkInt >= 31) {
          var scanStatus = await Permission.bluetoothScan.status;
          var connectStatus = await Permission.bluetoothConnect.status;
          permissionsGranted = scanStatus.isGranted && connectStatus.isGranted;
        }

        bool? classicAvail = await classic.FlutterBluetoothSerial.instance.isAvailable;
        bool? classicEnabled = await classic.FlutterBluetoothSerial.instance.isEnabled;
        available = classicAvail ?? false;
        enabled = classicEnabled ?? false;

        if (!available) {
          available = await ble.FlutterBluePlus.isSupported;
        }
        if (!enabled) {
          final adapterState = await ble.FlutterBluePlus.adapterState.first;
          enabled = adapterState == ble.BluetoothAdapterState.on;
        }
      } else if (Platform.isIOS) {
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

      var locationResult = await Permission.locationWhenInUse.request();
      if (locationResult.isPermanentlyDenied) {
        onStatusChanged?.call('Location permission may be needed for Bluetooth scanning');
      }
    }

    return true;
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;

    _isScanning = true;
    _devices.clear();
    onScanStateChanged?.call(true);
    onStatusChanged?.call('Scanning for devices...');

    if (Platform.isIOS) {
      await _startBleScan(timeout);
      await Future.delayed(timeout);
      await stopScan();
    } else {
      await Future.wait([
        _startClassicScan(timeout),
        _startBleScan(timeout),
      ]);
      await Future.delayed(timeout);
      await stopScan();
    }

    onStatusChanged?.call('Scan complete - ${_devices.length} devices found');
  }

  Future<void> _startClassicScan(Duration timeout) async {
    try {
      _classicScanSub = classic.FlutterBluetoothSerial.instance.startDiscovery()
        .listen(
          (result) {
            String name = result.device.name ?? 'Unknown Device';
            print("Classic Scanned MAC: ${result.device.address} | Name: $name");
            _addDevice(ObdDevice(
              id: result.device.address,
              name: name,
              type: BluetoothType.classic,
              isPaired: result.device.isBonded,
            ));
          },
          onError: (e) {
            onStatusChanged?.call('Classic scan error: $e');
          },
          onDone: () {},
        );

      Future.delayed(timeout, () {
        _classicScanSub?.cancel();
        _classicScanSub = null;
      });
    } catch (e) {
      onStatusChanged?.call('Failed to start classic scan: $e');
    }
  }

  Future<void> _startBleScan(Duration timeout) async {
    try {
      if (!await ble.FlutterBluePlus.isSupported) return;

      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      if (adapterState != ble.BluetoothAdapterState.on) return;

      await ble.FlutterBluePlus.startScan(timeout: timeout);

      _bleScanSub = ble.FlutterBluePlus.scanResults.listen(
        (results) {
          for (var result in results) {
            // Filter: skip very weak signals (likely ghost/background noise)
            final rssi = result.rssi ?? -100;
            if (rssi < -90) continue;

                print("Scanned MAC: ${result.device.remoteId.str} | OS Name: ${result.device.platformName} | Adv Name: ${result.advertisementData.localName}");

            String deviceName = result.advertisementData.localName.isNotEmpty
                ? result.advertisementData.localName
                : (result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device');

            if (!_devices.any((d) => d.id == result.device.remoteId.str && d.type == BluetoothType.ble)) {
              _addDevice(ObdDevice(
                id: result.device.remoteId.str,
                name: deviceName,
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

  void _addDevice(ObdDevice device) {
    bool exists = _devices.any((d) => d.id == device.id && d.type == device.type);
    if (!exists) {
      _devices.add(device);
      onDevicesFound?.call(List.from(_devices));
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    _isScanning = false;

    try {
      _classicScanSub?.cancel();
      _classicScanSub = null;

      if (ble.FlutterBluePlus.isScanningNow) {
        await ble.FlutterBluePlus.stopScan();
      }
      _bleScanSub?.cancel();
      _bleScanSub = null;
    } catch (e) {
      // Ignore errors during cleanup
    }

    onScanStateChanged?.call(false);
  }

  List<ObdDevice> get devices => List.from(_devices);
  List<ObdDevice> get obdDevices =>
      _devices.where((d) => d.isObdAdapter).toList();

  void dispose() {
    stopScan();
  }
}