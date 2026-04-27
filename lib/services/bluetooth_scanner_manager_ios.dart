import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'models/obd_device.dart';

/// iOS Bluetooth Scanner - BLE only (no Classic Bluetooth)
/// Lazy initialization to avoid state issues on app restart
class BluetoothScannerManager {
  Function(List<ObdDevice> devices)? onDevicesFound;
  Function(String message)? onStatusChanged;
  Function(bool isScanning)? onScanStateChanged;

  final List<ObdDevice> _devices = [];
  StreamSubscription? _bleScanSub;
  bool _isScanning = false;

  BluetoothScannerManager();

  bool get isScanning => _isScanning;

  Future<({bool available, bool enabled, bool permissionsGranted})> checkStatus() async {
    try {
      final isSupported = await ble.FlutterBluePlus.isSupported;
      if (!isSupported) {
        return (available: false, enabled: false, permissionsGranted: false);
      }

      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      final enabled = adapterState == ble.BluetoothAdapterState.on;

      return (available: true, enabled: enabled, permissionsGranted: true);
    } catch (e) {
      return (available: false, enabled: false, permissionsGranted: false);
    }
  }

  Future<bool> requestPermissions() async => true;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;

    _isScanning = true;
    _devices.clear();
    onScanStateChanged?.call(true);
    onStatusChanged?.call('Scanning for devices...');

    try {
      final isSupported = await ble.FlutterBluePlus.isSupported;
      if (!isSupported) {
        onStatusChanged?.call('BLE not supported');
        await _safeStop();
        return;
      }

      final adapterState = await ble.FlutterBluePlus.adapterState.first;
      if (adapterState != ble.BluetoothAdapterState.on) {
        onStatusChanged?.call('Please enable Bluetooth');
        await _safeStop();
        return;
      }

      await ble.FlutterBluePlus.startScan(timeout: timeout);

      _bleScanSub = ble.FlutterBluePlus.scanResults.listen(
        (results) {
          for (var result in results) {
            print("BLE Scanned MAC: ${result.device.remoteId.str} | OS Name: ${result.device.platformName} | Adv Name: ${result.advertisementData.localName}");

            String deviceName = result.advertisementData.localName.isNotEmpty
                ? result.advertisementData.localName
                : (result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : 'Unknown Device');

            if (!_devices.any((d) => d.id == result.device.remoteId.str)) {
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

      await Future.delayed(timeout);
      await _safeStop();

      onStatusChanged?.call('Scan complete - ${_devices.length} devices found');
    } catch (e) {
      onStatusChanged?.call('Scan failed: $e');
      await _safeStop();
    }
  }

  Future<void> _safeStop() async {
    _isScanning = false;
    try {
      _bleScanSub?.cancel();
      _bleScanSub = null;
      if (ble.FlutterBluePlus.isScanningNow) {
        await ble.FlutterBluePlus.stopScan();
      }
    } catch (_) {}
    onScanStateChanged?.call(false);
  }

  void _addDevice(ObdDevice device) {
    if (!_devices.any((d) => d.id == device.id)) {
      _devices.add(device);
      onDevicesFound?.call(List.from(_devices));
    }
  }

  Future<void> stopScan() async {
    await _safeStop();
  }

  List<ObdDevice> get devices => List.from(_devices);
  List<ObdDevice> get obdDevices => _devices.where((d) => d.isObdAdapter).toList();

  void dispose() {
    _bleScanSub?.cancel();
    _bleScanSub = null;
  }
}