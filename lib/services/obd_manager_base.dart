import 'package:flutter/foundation.dart';
import 'connections/obd_connection.dart';
import 'models/obd_device.dart';
import 'obd_service.dart';

/// Abstract base class for OBD Manager implementations
/// Both iOS and Android managers must implement all these methods
abstract class ObdManagerBase extends ChangeNotifier {
  ObdConnection? get connection;
  bool get isInitialized;
  bool get isConnected;
  String get statusMessage;
  List<ObdDevice> get discoveredDevices;
  List<String> get storedCodes;
  Map<String, String> get liveData;
  VehicleInfo get vehicleInfo;
  String? get connectedDeviceName;
  bool get isScanning;

  void initialize();
  Future<void> disconnect();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> connectToDevice(ObdDevice device);
  Future<void> readCodes();
  Future<void> readLiveData();
  void clearCodes();
  Future<bool> clearDTCs();
  Future<void> scanForDevices();
  Future<({bool available, bool enabled, bool permissions})> checkBluetoothStatus();
}