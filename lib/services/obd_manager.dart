// Factory pattern - routes to correct manager at runtime based on OS
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'obd_manager_base.dart';
import 'obd_manager_android.dart';
import 'obd_manager_ios.dart';
import 'connections/obd_connection.dart';
import 'models/obd_device.dart';
import 'obd_service.dart';

/// ObdManager - factory + ChangeNotifier wrapper
/// UI code uses ObdManager as a ChangeNotifier directly
/// Internally creates the right platform-specific manager at runtime
class ObdManager extends ChangeNotifier {
  late final ObdManagerBase _delegate;

  ObdManager() {
    _delegate = _createManager();
    _delegate.addListener(_onDelegateChanged);
  }

  ObdManagerBase _createManager() {
    if (Platform.isIOS) {
      // Reset BLE state on iOS to prevent crash on app restart
      _resetBleState();
      return ObdManagerIos();
    } else if (Platform.isAndroid) {
      return ObdManagerAndroid();
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Reset BLE state on iOS to prevent crashes after app restart
  /// FlutterBluePlus can hold stale state when app is killed and restarted
  Future<void> _resetBleState() async {
    try {
      if (ble.FlutterBluePlus.isScanningNow) {
        ble.FlutterBluePlus.stopScan();
      }
      // Ignore errors - just try to clean up
    } catch (_) {}
  }

  void _onDelegateChanged() {
    notifyListeners();
  }

  // Delegate all getters and methods
  ObdConnection? get connection => _delegate.connection;
  bool get isInitialized => _delegate.isInitialized;
  bool get isConnected => _delegate.isConnected;
  String get statusMessage => _delegate.statusMessage;
  List<ObdDevice> get discoveredDevices => _delegate.discoveredDevices;
  List<String> get storedCodes => _delegate.storedCodes;
  Map<String, String> get liveData => _delegate.liveData;
  VehicleInfo get vehicleInfo => _delegate.vehicleInfo;
  String? get connectedDeviceName => _delegate.connectedDeviceName;
  bool get isScanning => _delegate.isScanning;

  void initialize() => _delegate.initialize();
  Future<void> disconnect() => _delegate.disconnect();
  Future<void> startScan() => _delegate.startScan();
  Future<void> stopScan() => _delegate.stopScan();
  Future<bool> connectToDevice(ObdDevice device) => _delegate.connectToDevice(device);
  Future<void> readCodes() => _delegate.readCodes();
  Future<void> readLiveData() => _delegate.readLiveData();
  void clearCodes() => _delegate.clearCodes();
  Future<bool> clearDTCs() => _delegate.clearDTCs();
  Future<void> scanForDevices() => _delegate.scanForDevices();
  Future<({bool available, bool enabled, bool permissions})> checkBluetoothStatus() =>
      _delegate.checkBluetoothStatus();

  @override
  void dispose() {
    _delegate.removeListener(_onDelegateChanged);
    super.dispose();
  }
}
