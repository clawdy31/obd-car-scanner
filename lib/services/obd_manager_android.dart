// Android: Supports both Classic Bluetooth and BLE
import 'dart:async';
import 'obd_manager_base.dart';
import 'bluetooth_scanner_manager.dart';
import 'obd_service.dart';
import 'connections/classic_obd_connection_real.dart';
import 'connections/ble_obd_connection.dart';
import 'connections/obd_connection.dart';
import 'models/obd_device.dart';

/// Android OBD Manager - supports Classic Bluetooth and BLE
class ObdManagerAndroid extends ObdManagerBase {
  final BluetoothScannerManager _scanner = BluetoothScannerManager();

  ObdConnection? _connection;
  ObdService? _obdService;

  bool _isInitialized = false;
  List<ObdDevice> _discoveredDevices = [];
  final List<String> _storedCodes = [];
  final Map<String, String> _liveData = {};
  VehicleInfo _vehicleInfo = VehicleInfo.empty();
  String _statusMessage = '';
  bool _isConnecting = false;
  String? _connectedDeviceName;
  bool _isPolling = false;
  Completer<void>? _pollingCompleter;

  @override
  ObdConnection? get connection => _connection;
  @override
  bool get isInitialized => _isInitialized;
  @override
  bool get isConnected => _connection?.isConnected ?? false;
  @override
  String get statusMessage => _statusMessage;
  @override
  List<ObdDevice> get discoveredDevices => _discoveredDevices;
  @override
  List<String> get storedCodes => List.unmodifiable(_storedCodes);
  @override
  Map<String, String> get liveData => Map.unmodifiable(_liveData);
  @override
  VehicleInfo get vehicleInfo => _vehicleInfo;
  @override
  String? get connectedDeviceName => _connectedDeviceName;
  @override
  bool get isScanning => _scanner.isScanning;

  ObdManagerAndroid() {
    _scanner.onDevicesFound = (devices) {
      _discoveredDevices = devices;
      notifyListeners();
    };
    _scanner.onStatusChanged = (message) {
      _statusMessage = message;
      notifyListeners();
    };
    _scanner.onScanStateChanged = (scanning) {
      notifyListeners();
    };
  }

  @override
  void initialize() {
    startScan();
  }

  @override
  Future<void> scanForDevices() async => await startScan();

  @override
  Future<void> startScan() async => await _scanner.startScan();

  @override
  Future<void> stopScan() async => _scanner.stopScan();

  ObdConnection _createConnection(BluetoothType type) {
    if (type == BluetoothType.classic) return ClassicObdConnection();
    return BleObdConnection();
  }

  @override
  Future<bool> connectToDevice(ObdDevice device) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    _statusMessage = 'Connecting to ${device.name}...';
    notifyListeners();

    try {
      _connection = _createConnection(device.type);
      _connection!.stateStream.listen((state) {
        if (state == ConnectionState.connected) {
          _statusMessage = 'Connected to ${device.name}';
          _startPolling();
        } else if (state == ConnectionState.disconnected) {
          _statusMessage = 'Disconnected';
          _stopPolling();
        }
        notifyListeners();
      });
      _connection!.dataStream.listen((data) => _processObdData(data));

      bool success = await _connection!.connect(device.id);
      if (success) {
        _connectedDeviceName = device.name;
        _obdService = ObdService(_connection!);
        _isInitialized = true;
        await _initializeObd();
      }
      return success;
    } catch (e) {
      _statusMessage = 'Connection failed: $e';
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> _initializeObd() async {
    if (_obdService == null) return;
    _statusMessage = 'Initializing OBD...';
    notifyListeners();
    try {
      await _obdService!.sendCommand('ATZ');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _obdService!.sendCommand('ATE0');
      await Future.delayed(const Duration(milliseconds: 100));
      await _obdService!.sendCommand('ATL0');
      await Future.delayed(const Duration(milliseconds: 100));
      await _obdService!.sendCommand('ATSP0');
      await Future.delayed(const Duration(milliseconds: 100));
      _vehicleInfo = VehicleInfo.empty();
      _statusMessage = 'Ready';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'OBD init failed: $e';
      notifyListeners();
    }
  }

  void _processObdData(String data) {
    if (data.contains('43') || data.contains('01')) _parseDtcResponse(data);
    if (data.contains('010C') || data.contains('010D')) _parseLiveData(data);
  }

  void _parseDtcResponse(String response) {
    final codePattern = RegExp(r'[PCBF][0-9A-Fa-f]{3}');
    for (final match in codePattern.allMatches(response.toUpperCase())) {
      if (!_storedCodes.contains(match.group(0))) _storedCodes.add(match.group(0)!);
    }
    notifyListeners();
  }

  void _parseLiveData(String data) {
    if (data.contains('010C')) {
      final rpmMatch = RegExp(r'41 0C ([0-9A-Fa-f]{2}) ([0-9A-Fa-f]{2})').firstMatch(data);
      if (rpmMatch != null) {
        final rpm = (int.parse(rpmMatch.group(1)!, radix: 16) * 256 +
                     int.parse(rpmMatch.group(2)!, radix: 16)) ~/ 4;
        _liveData['RPM'] = rpm.toString();
      }
    }
    if (data.contains('010D')) {
      final speedMatch = RegExp(r'41 0D ([0-9A-Fa-f]{2})').firstMatch(data);
      if (speedMatch != null) {
        _liveData['Speed'] = '${int.parse(speedMatch.group(1)!, radix: 16)} km/h';
      }
    }
    notifyListeners();
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollingLoop();
  }

  void _stopPolling() {
    _isPolling = false;
    _pollingCompleter?.complete();
  }

  Future<void> _pollingLoop() async {
    _pollingCompleter = Completer<void>();
    while (_isPolling && _connection?.isConnected == true) {
      try {
        final dtcResponse = await _obdService!.sendCommand('03');
        if (dtcResponse.isNotEmpty) _processObdData(dtcResponse);
        await Future.delayed(const Duration(seconds: 2));
        if (_storedCodes.isNotEmpty) await _obdService!.sendCommand('02');
        await Future.delayed(const Duration(seconds: 5));
        await _obdService!.sendCommand('0100');
      } catch (e) {
        _statusMessage = 'Polling error: $e';
      }
    }
    _pollingCompleter?.complete();
  }

  @override
  Future<void> disconnect() async {
    _stopPolling();
    await _connection?.disconnect();
    _connection = null;
    _obdService = null;
    _isInitialized = false;
    _connectedDeviceName = null;
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  @override
  void clearCodes() {
    _storedCodes.clear();
    notifyListeners();
  }

  @override
  Future<bool> clearDTCs() async {
    if (_obdService == null || !isConnected) return false;
    try {
      await _obdService!.sendCommand('04');
      _storedCodes.clear();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> readCodes() async {
    if (_obdService == null || !isConnected) return;
    _statusMessage = 'Reading codes...';
    notifyListeners();
    final response = await _obdService!.sendCommand('03');
    _statusMessage = response.contains('NODATA') ? 'No codes stored' : '${_storedCodes.length} codes found';
    notifyListeners();
  }

  @override
  Future<void> readLiveData() async {
    if (_obdService == null || !isConnected) return;
    final rpmResponse = await _obdService!.sendCommand('010C');
    _processObdData(rpmResponse);
    final speedResponse = await _obdService!.sendCommand('010D');
    _processObdData(speedResponse);
    final tempResponse = await _obdService!.sendCommand('0105');
    _processObdData(tempResponse);
    notifyListeners();
  }

  @override
  Future<({bool available, bool enabled, bool permissions})> checkBluetoothStatus() async {
    final result = await _scanner.checkStatus();
    return (available: result.available, enabled: result.enabled, permissions: result.permissionsGranted);
  }
}