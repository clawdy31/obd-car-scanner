import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'connections/obd_connection.dart';
import 'connections/classic_obd_connection.dart';
import 'connections/ble_obd_connection.dart';
import 'bluetooth_scanner_manager.dart';
import 'models/obd_device.dart';
import 'obd_service.dart';

/// Unified OBD Manager - combines scanning and connection
/// Uses Adapter pattern to support both Classic and BLE
class ObdManager extends ChangeNotifier with WidgetsBindingObserver {
  final BluetoothScannerManager _scanner;
  
  ObdConnection? _connection;
  ObdService? _obdService;
  
  bool _isInitialized = false;
  bool _isBluetoothAvailable = false;
  bool _isBluetoothEnabled = false;
  bool _hasPermissions = false;
  
  List<ObdDevice> _discoveredDevices = [];
  List<String> _storedCodes = [];
  Map<String, String> _liveData = {};
  VehicleInfo _vehicleInfo = VehicleInfo.empty();
  String _statusMessage = '';
  bool _isConnecting = false;
  String? _connectedDeviceName;

  // Polling state machine
  bool _isPolling = false;
  bool _shouldResumePolling = false;
  
  // Polling loop task
  Future<void>? _pollingTask;
  Completer<void>? _pollingCompleter;

  BluetoothType? _selectedDeviceType;

  ObdManager() : _scanner = BluetoothScannerManager() {
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

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  // ============================================================
  // LIFECYCLE OBSERVER
  // ============================================================
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausePolling();
        break;
      case AppLifecycleState.resumed:
        _resumePolling();
        break;
      case AppLifecycleState.detached:
        _stopPolling();
        break;
    }
  }

  // ============================================================
  // POLLING STATE MACHINE - Self-Regulating Loop
  // ============================================================

  /// Start the polling loop
  void _startPolling() {
    if (_isPolling) return; // Already running
    if (!isConnected) return; // Not connected

    _isPolling = true;
    _shouldResumePolling = true;
    
    // Start the polling loop (fire and forget)
    _pollingTask = _pollingLoop();
  }

  /// Pause polling - called when app goes to background
  void _pausePolling() {
    if (!_isPolling) return;
    
    _shouldResumePolling = false;
    _isPolling = false;
    _statusMessage = 'Polling paused (backgrounded)';
    notifyListeners();
  }

  /// Resume polling - called when app returns to foreground
  void _resumePolling() {
    if (!isConnected) return; // Need connection to resume
    if (_isPolling && _shouldResumePolling) return; // Already running

    _shouldResumePolling = true;
    _isPolling = true;
    _statusMessage = 'Resuming...';
    notifyListeners();
    
    // Start loop if not already running
    if (_pollingTask == null) {
      _pollingTask = _pollingLoop();
    }
  }

  /// Stop polling completely - called on disconnect or dispose
  void _stopPolling() {
    _isPolling = false;
    _shouldResumePolling = false;
    _pollingTask = null;
  }

  /// Self-regulating polling loop using while instead of Timer
  Future<void> _pollingLoop() async {
    _pollingCompleter = Completer<void>();
    
    try {
      while (true) {
        // Check stop condition
        if (!_isPolling || !_shouldResumePolling) {
          break;
        }
        
        // Check if still connected
        if (_connection == null || !_connection!.isConnected) {
          _onDisconnected();
          break;
        }
        
        try {
          // Execute one poll cycle and await completion
          await _pollData();
        } catch (e) {
          // Handle Bluetooth disconnect or errors gracefully
          if (e is StateError || 
              e is ObdConnectionException ||
              e.toString().contains('disconnected') ||
              e.toString().contains('Bluetooth')) {
            _onDisconnected();
            break;
          }
          // For other errors, continue polling
          _statusMessage = 'Poll error: $e';
          notifyListeners();
        }
        
        // Wait before next cycle - guarantees no overlap
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } finally {
      _pollingTask = null;
      _pollingCompleter?.complete();
      _pollingCompleter = null;
    }
  }

  // ============================================================
  // Getters
  // ============================================================

  bool get isConnected => _connection?.isConnected ?? false;
  bool get isBluetoothAvailable => _isBluetoothAvailable;
  bool get isBluetoothEnabled => _isBluetoothEnabled;
  bool get hasPermissions => _hasPermissions;
  bool get isScanning => _scanner.isScanning;
  bool get isConnecting => _isConnecting;
  bool get isPolling => _isPolling;
  List<ObdDevice> get discoveredDevices => _discoveredDevices;
  List<ObdDevice> get obdDevices => _scanner.obdDevices;
  List<String> get storedCodes => _storedCodes;
  Map<String, String> get liveData => _liveData;
  VehicleInfo get vehicleInfo => _vehicleInfo;
  String get statusMessage => _statusMessage;
  String? get connectedDeviceName => _connectedDeviceName;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    var status = await _scanner.checkStatus();
    
    _isBluetoothAvailable = status.available;
    _isBluetoothEnabled = status.enabled;
    _hasPermissions = status.permissionsGranted;

    if (!_hasPermissions) {
      _hasPermissions = await _scanner.requestPermissions();
    }

    if (_isBluetoothAvailable && _isBluetoothEnabled && _hasPermissions) {
      _statusMessage = 'Bluetooth ready';
    } else if (!_isBluetoothEnabled) {
      _statusMessage = 'Please enable Bluetooth';
    } else if (!_hasPermissions) {
      _statusMessage = 'Bluetooth permissions required';
    } else {
      _statusMessage = 'Bluetooth not available';
    }

    _isInitialized = true;
    notifyListeners();
  }

  // ============================================================
  // BLUETOOTH OPERATIONS
  // ============================================================

  Future<void> enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
      _isBluetoothEnabled = true;
      _statusMessage = 'Bluetooth enabled';
    } catch (e) {
      _statusMessage = 'Failed to enable Bluetooth';
    }
    notifyListeners();
  }

  Future<void> scanForDevices() async {
    if (!_isBluetoothEnabled) {
      _statusMessage = 'Please enable Bluetooth first';
      notifyListeners();
      return;
    }

    if (!_hasPermissions) {
      _hasPermissions = await _scanner.requestPermissions();
      if (!_hasPermissions) {
        _statusMessage = 'Bluetooth permissions required';
        notifyListeners();
        return;
      }
    }

    _discoveredDevices = [];
    await _scanner.startScan();
  }

  Future<void> stopScan() async {
    await _scanner.stopScan();
  }

  Future<void> connectToDevice(ObdDevice device) async {
    _isConnecting = true;
    _statusMessage = 'Connecting to ${device.displayName}...';
    _selectedDeviceType = device.type;
    _connectedDeviceName = device.displayName;
    notifyListeners();

    try {
      // Clean up existing connection
      _stopPolling();
      _connection?.dispose();
      _connection = null;
      _obdService?.dispose();
      _obdService = null;

      // Create appropriate connection based on device type
      if (device.type == BluetoothType.classic) {
        _connection = ClassicObdConnection();
      } else {
        _connection = BleObdConnection();
      }

      // Set up connection state listener for disconnect handling
      _connection!.stateStream.listen((state) {
        if (state == ConnectionState.connected) {
          _onConnected();
        } else if (state == ConnectionState.disconnected || state == ConnectionState.error) {
          _onDisconnected();
        }
      });

      // Connect
      bool success = await _connection!.connect(device.id);

      if (!success) {
        throw Exception('Connection failed');
      }
    } catch (e) {
      _isConnecting = false;
      _statusMessage = 'Connection failed: $e';
      _connection?.dispose();
      _connection = null;
      notifyListeners();
    }
  }

  void _onConnected() {
    _isConnecting = false;
    _statusMessage = 'Connected - Initializing OBD...';
    notifyListeners();

    // Initialize OBD service
    _obdService = ObdService(_connection!);
    _obdService!.onError = (error) {
      _statusMessage = error;
      notifyListeners();
    };
    _obdService!.onConnectionStateChanged = (connected) {
      if (connected) {
        _statusMessage = 'OBD Initialized';
        _startPolling();
        _readDTCs();
        _readVehicleInfo();
      }
    };
    _obdService!.initialize();
  }

  void _onDisconnected() {
    _stopPolling();
    _storedCodes = [];
    _liveData = {};
    _statusMessage = 'Disconnected';
    _isConnecting = false;
    _connection = null;
    _obdService = null;
    _connectedDeviceName = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    _stopPolling();
    await _connection?.disconnect();
    _connection?.dispose();
    _connection = null;
    _obdService?.dispose();
    _obdService = null;
    _storedCodes = [];
    _liveData = {};
    _statusMessage = 'Disconnected';
    notifyListeners();
  }

  // ============================================================
  // DATA OPERATIONS
  // ============================================================

  /// Poll all OIDs - awaits entire batch before returning
  Future<void> _pollData() async {
    if (_obdService == null || !_obdService!.isConnected) return;

    try {
      Map<String, String> data = await _obdService!.queryAllPids();
      if (data.isNotEmpty) {
        _liveData = data;
        notifyListeners();
      }
    } catch (e) {
      // Re-throw so polling loop can handle disconnect
      rethrow;
    }
  }

  Future<void> _readDTCs() async {
    if (_obdService == null) return;

    try {
      _storedCodes = await _obdService!.readDTCs();
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to read DTCs';
    }
  }

  Future<void> _readVehicleInfo() async {
    if (_obdService == null) return;

    try {
      _vehicleInfo = await _obdService!.readVehicleInfo();
      notifyListeners();
    } catch (e) {
      // Silent fail
    }
  }

  Future<bool> clearDTCs() async {
    if (_obdService == null || !_obdService!.isConnected) return false;

    bool success = await _obdService!.clearDTCs();
    if (success) {
      _storedCodes = [];
      _statusMessage = 'DTCs cleared';
      notifyListeners();
    }
    return success;
  }

  Future<void> refresh() async {
    if (!isConnected) return;
    
    // Force an immediate poll
    await _pollData();
    await _readDTCs();
    await _readVehicleInfo();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop polling
    _stopPolling();
    
    // Clean up resources
    _scanner.dispose();
    _connection?.dispose();
    _obdService?.dispose();
    
    super.dispose();
  }
}
