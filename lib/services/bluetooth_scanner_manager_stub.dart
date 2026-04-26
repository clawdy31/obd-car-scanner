import 'models/obd_device.dart';

/// iOS stub - Classic Bluetooth not supported, only BLE
class BluetoothScannerManager {
  Function(List<ObdDevice> devices)? onDevicesFound;
  Function(String message)? onStatusChanged;
  Function(bool isScanning)? onScanStateChanged;

  final List<ObdDevice> _devices = [];
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  Future<({bool available, bool enabled, bool permissionsGranted})> checkStatus() async {
    // iOS only uses BLE - delegate to flutter_blue_plus
    return (available: true, enabled: true, permissionsGranted: true);
  }

  Future<bool> requestPermissions() async => true;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    if (_isScanning) return;
    _isScanning = true;
    onScanStateChanged?.call(true);
    onStatusChanged?.call('Scanning for devices... (BLE only)');

    // On iOS, only start BLE scan (handled by real impl via conditional import)
    await Future.delayed(timeout);
    _isScanning = false;
    onScanStateChanged?.call(false);
    onStatusChanged?.call('Scan complete - ${_devices.length} devices found');
  }

  Future<void> stopScan() async {
    _isScanning = false;
    onScanStateChanged?.call(false);
  }

  List<ObdDevice> get devices => List.from(_devices);
  List<ObdDevice> get obdDevices => _devices.where((d) => d.isObdAdapter).toList();

  void dispose() {
    stopScan();
  }
}