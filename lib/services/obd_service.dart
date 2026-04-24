import 'dart:async';
import 'connections/obd_connection.dart';

/// OBD-II Service - Communicates with ELM327-compatible adapters
/// Now decoupled from Bluetooth - uses ObdConnection interface
class ObdService {
  final ObdConnection _connection;
  
  Function(DataPacket)? onDataReceived;
  Function(String)? onError;
  Function(bool)? onConnectionStateChanged;

  StreamSubscription? _dataSubscription;
  StreamSubscription? _stateSubscription;
  bool _isConnected = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  // Response buffer for chunked data
  String _responseBuffer = '';

  ObdService(this._connection);

  bool get isConnected => _isConnected;

  /// Initialize OBD connection and set up listeners
  void initialize() {
    // Listen to connection state changes
    _stateSubscription = _connection.stateStream.listen((state) {
      bool wasConnected = _isConnected;
      _isConnected = state == ConnectionState.connected;
      
      onConnectionStateChanged?.call(_isConnected);
      
      if (_isConnected && !wasConnected) {
        // Just connected - start initialization
        _initializeAdapter();
      } else if (!_isConnected && wasConnected) {
        // Just disconnected
        _cleanup();
      }
    });

    // Listen to data stream
    _dataSubscription = _connection.dataStream.listen(
      (data) {
        _responseBuffer += data;
        // Check if we have a complete response (ends with '>')
        if (_responseBuffer.contains('>')) {
          // Process complete response
          _processBuffer();
        }
      },
      onError: (e) {
        onError?.call('Data stream error: $e');
      },
    );
  }

  /// Initialize ELM327 adapter with auto-protocol negotiation
  Future<bool> _initializeAdapter() async {
    // Try auto protocol first, then specific protocols if needed
    List<String> protocols = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C'];
    
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        // Reset ELM327
        onError?.call('Initializing ELM327... (${attempt == 0 ? 'auto' : 'retry'})');
        
        String resetResponse = await _connection.writeWithResponse('ATZ', timeout: const Duration(seconds: 2));
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if adapter responded
        if (resetResponse.contains('ELM') || resetResponse.contains('OK')) {
          onError?.call('Adapter reset successful');
        }

        // Disable echo
        await _connection.writeWithResponse('ATE0', timeout: const Duration(milliseconds: 500));
        await Future.delayed(const Duration(milliseconds: 200));

        // Set protocol
        String protocol = attempt == 0 ? '0' : protocols[attempt - 1];
        await _connection.writeWithResponse('ATSP$protocol', timeout: const Duration(milliseconds: 500));
        await Future.delayed(const Duration(milliseconds: 200));

        // Disable headers
        await _connection.writeWithResponse('ATH0', timeout: const Duration(milliseconds: 500));
        await Future.delayed(const Duration(milliseconds: 200));

        // Set line breaks off
        await _connection.writeWithResponse('ATL0', timeout: const Duration(milliseconds: 500));
        await Future.delayed(const Duration(milliseconds: 200));

        // Try a test query to verify connection
        String testResponse = await _connection.writeWithResponse('0100', timeout: const Duration(milliseconds: 1000));
        
        if (!testResponse.contains('NODATA') && !testResponse.contains('ERROR')) {
          onError?.call('OBD connection established');
          return true;
        }

        if (attempt == 0) {
          onError?.call('Retrying with different protocol...');
        }
      } catch (e) {
        onError?.call('Init attempt $attempt failed: $e');
      }
    }

    onError?.call('Could not establish OBD communication');
    return false;
  }

  void _processBuffer() {
    // Split by prompt and process each complete response
    List<String> responses = _responseBuffer.split('>');
    for (var response in responses) {
      if (response.trim().isNotEmpty) {
        // Emit data packet (could be parsed further)
        onDataReceived?.call(DataPacket(
          pid: 'raw',
          value: response.trim(),
          raw: response,
        ));
      }
    }
    _responseBuffer = '';
  }

  /// Query a specific PID
  Future<DataPacket?> queryPid(String pid) async {
    if (!_isConnected) return null;

    try {
      String response = await _connection.writeWithResponse('01$pid', timeout: const Duration(seconds: 1));
      return parseResponse(response, '01$pid');
    } catch (e) {
      onError?.call('Query failed for PID $pid: $e');
      return null;
    }
  }

  /// Query all standard PIDs
  Future<Map<String, String>> queryAllPids() async {
    Map<String, String> data = {};

    // Common PIDs for petrol vehicles
    List<String> pids = ['0C', '0D', '05', '11', '04', '2F', '10'];

    for (String pid in pids) {
      DataPacket? packet = await queryPid(pid);
      if (packet != null) {
        data[packet.pid] = packet.value;
      }
      // Small delay between queries
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return data;
  }

  /// Parse OBD response string into DataPacket
  DataPacket? parseResponse(String response, String command) {
    if (response.isEmpty || response.contains('ERROR') || response.contains('NODATA')) {
      return null;
    }

    // Remove spaces and common noise
    String clean = response.replaceAll(' ', '').replaceAll('\r', '').replaceAll('>', '').trim();

    // Extract PID from command (e.g., '010C' -> '0C')
    String pid = '';
    if (command.length >= 4) {
      pid = command.substring(2, 4);
    }

    // Find data bytes (skip response code 41 XX)
    if (clean.length < 6) return null;

    String dataBytes = clean.substring(4);

    switch (pid) {
      case '0C': // Engine RPM
        if (dataBytes.length >= 4) {
          int a = int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0;
          int b = int.tryParse(dataBytes.substring(2, 4), radix: 16) ?? 0;
          int rpm = ((a * 256) + b) ~/ 4;
          return DataPacket(pid: 'rpm', value: rpm.toString(), raw: response);
        }
        break;
      case '0D': // Vehicle Speed
        if (dataBytes.length >= 2) {
          int speed = int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0;
          return DataPacket(pid: 'speed', value: speed.toString(), raw: response);
        }
        break;
      case '05': // Coolant Temperature
        if (dataBytes.length >= 2) {
          int temp = (int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0) - 40;
          return DataPacket(pid: 'coolant', value: temp.toString(), raw: response);
        }
        break;
      case '11': // Throttle Position
        if (dataBytes.length >= 2) {
          int throttle = ((int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0) * 100) ~/ 255;
          return DataPacket(pid: 'throttle', value: throttle.toString(), raw: response);
        }
        break;
      case '04': // Engine Load
        if (dataBytes.length >= 2) {
          int load = ((int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0) * 100) ~/ 255;
          return DataPacket(pid: 'load', value: load.toString(), raw: response);
        }
        break;
      case '2F': // Fuel Level
        if (dataBytes.length >= 2) {
          int fuel = ((int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0) * 100) ~/ 255;
          return DataPacket(pid: 'fuel', value: fuel.toString(), raw: response);
        }
        break;
      case '10': // MAF Air Flow Rate
        if (dataBytes.length >= 4) {
          int a = int.tryParse(dataBytes.substring(0, 2), radix: 16) ?? 0;
          int b = int.tryParse(dataBytes.substring(2, 4), radix: 16) ?? 0;
          double maf = ((a * 256) + b) / 100;
          return DataPacket(pid: 'maf', value: maf.toStringAsFixed(1), raw: response);
        }
        break;
    }

    return null;
  }

  /// Read DTCs (Diagnostic Trouble Codes)
  Future<List<String>> readDTCs() async {
    if (!_isConnected) return [];

    try {
      String response = await _connection.writeWithResponse('03', timeout: const Duration(seconds: 2));
      return _parseDTCs(response);
    } catch (e) {
      onError?.call('DTC read failed: $e');
      return [];
    }
  }

  List<String> _parseDTCs(String response) {
    List<String> codes = [];
    String clean = response.replaceAll(' ', '').replaceAll('43', '').replaceAll('\r', '').trim();
    
    if (clean.length >= 4 && !clean.contains('NODATA')) {
      // Extract DTCs (each DTC is 4 hex chars in mode 03)
      for (int i = 0; i + 4 <= clean.length; i += 4) {
        String dtc = clean.substring(i, i + 4);
        if (dtc != '0000') {
          codes.add(_formatDTC(dtc));
        }
      }
    }
    return codes;
  }

  String _formatDTC(String raw) {
    String prefix;
    int num = int.tryParse(raw, radix: 16) ?? 0;
    switch ((num >> 12) & 0x3) {
      case 0:
        prefix = 'P';
        break;
      case 1:
        prefix = 'C';
        break;
      case 2:
        prefix = 'B';
        break;
      default:
        prefix = 'U';
        break;
    }
    return '$prefix${(num & 0xFFF).toString().padLeft(3, '0')}';
  }

  /// Clear DTCs
  Future<bool> clearDTCs() async {
    if (!_isConnected) return false;

    try {
      String response = await _connection.writeWithResponse('04', timeout: const Duration(seconds: 2));
      return response.contains('44'); // '44' = DTCs cleared
    } catch (e) {
      onError?.call('Clear DTCs failed: $e');
      return false;
    }
  }

  /// Read vehicle info via Mode 09
  Future<VehicleInfo> readVehicleInfo() async {
    VehicleInfo info = VehicleInfo.empty();

    if (!_isConnected) return info;

    try {
      // Read VIN (PID 02)
      String vinResponse = await _connection.writeWithResponse('0902', timeout: const Duration(seconds: 2));
      if (!vinResponse.contains('NODATA')) {
        info.vin = _parseVIN(vinResponse);
      }

      // Read Calibration ID (PID 04)
      String calResponse = await _connection.writeWithResponse('0904', timeout: const Duration(seconds: 2));
      if (!calResponse.contains('NODATA')) {
        info.calibrationId = _parseCalibrationID(calResponse);
      }

      // Read ECU Name (PID 0A)
      String ecuResponse = await _connection.writeWithResponse('090A', timeout: const Duration(seconds: 2));
      if (!ecuResponse.contains('NODATA')) {
        info.ecuName = _parseCalibrationID(ecuResponse);
      }

      // Read OBD Type (PID 1C)
      String obdResponse = await _connection.writeWithResponse('011C', timeout: const Duration(seconds: 1));
      info.obdStandard = _parseOBDType(obdResponse);

    } catch (e) {
      onError?.call('Vehicle info read failed: $e');
    }

    return info;
  }

  String _parseVIN(String response) {
    String clean = response.replaceAll(' ', '').replaceAll('4902', '').replaceAll('\r', '').replaceAll('>', '').trim();
    if (clean.length < 34) return '';
    
    StringBuffer vin = StringBuffer();
    for (int i = 0; i + 1 < clean.length && vin.length < 17; i += 2) {
      int charCode = int.tryParse(clean.substring(i, i + 2), radix: 16) ?? 0;
      if (charCode >= 32 && charCode <= 126) {
        vin.write(String.fromCharCode(charCode));
      }
    }
    return vin.toString();
  }

  String _parseCalibrationID(String response) {
    String clean = response.replaceAll(' ', '').replaceAll(RegExp(r'490[24]'), '').replaceAll('\r', '').replaceAll('>', '').trim();
    
    StringBuffer id = StringBuffer();
    for (int i = 0; i + 1 < clean.length; i += 2) {
      int charCode = int.tryParse(clean.substring(i, i + 2), radix: 16) ?? 0;
      if (charCode >= 32 && charCode <= 126) {
        id.write(String.fromCharCode(charCode));
      }
    }
    return id.toString().trim();
  }

  String _parseOBDType(String response) {
    String clean = response.replaceAll(' ', '').replaceAll('4101', '').trim();
    if (clean.length < 2) return 'Unknown';
    
    int typeCode = int.tryParse(clean.substring(0, 2), radix: 16) ?? 0;
    switch (typeCode) {
      case 1: return 'OBD-II (CARB)';
      case 2: return 'OBD (EPA)';
      case 3: return 'OBD & OBD-II';
      case 4: return 'OBD-I';
      case 5: return 'Not OBD compliant';
      default: return 'Unknown ($typeCode)';
    }
  }

  void _cleanup() {
    _responseBuffer = '';
    _retryCount = 0;
  }

  void dispose() {
    _dataSubscription?.cancel();
    _stateSubscription?.cancel();
  }
}

/// Data packet from OBD query
class DataPacket {
  final String pid;
  final String value;
  final String raw;
  final DateTime timestamp;

  DataPacket({
    required this.pid,
    required this.value,
    required this.raw,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Vehicle information from OBD
class VehicleInfo {
  String vin;
  String calibrationId;
  String ecuName;
  String obdStandard;
  String intakeAirTemp;
  String runtime;

  VehicleInfo({
    this.vin = '',
    this.calibrationId = '',
    this.ecuName = '',
    this.obdStandard = '',
    this.intakeAirTemp = '',
    this.runtime = '',
  });

  factory VehicleInfo.empty() => VehicleInfo();

  bool get hasData => vin.isNotEmpty || calibrationId.isNotEmpty || ecuName.isNotEmpty;
}
