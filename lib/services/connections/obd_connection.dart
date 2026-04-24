import 'dart:async';

/// Connection state enumeration
enum ConnectionState {
  disconnected,  // Not connected
  connecting,    // Attempting to connect
  connected,     // Successfully connected
  disconnecting, // Gracefully disconnecting
  error,         // Connection error occurred
}

/// Abstract interface for OBD connections
/// All Bluetooth communication goes through this interface
abstract class ObdConnection {
  /// Stream of data received from the ELM327 adapter
  Stream<String> get dataStream;
  
  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream;
  
  /// Current connection state
  ConnectionState get currentState;
  
  /// Whether currently connected
  bool get isConnected => currentState == ConnectionState.connected;

  /// Connect to a device by its ID
  /// [deviceId] - MAC address for Classic, MAC/UUID for BLE
  /// Returns true if connection successful
  Future<bool> connect(String deviceId);
  
  /// Disconnect from current device
  Future<void> disconnect();
  
  /// Write a command to the ELM327
  /// Carriage return is automatically appended
  Future<void> write(String command);
  
  /// Write a command and wait for response
  /// Returns the response string, or throws on timeout/error
  Future<String> writeWithResponse(String command, {Duration timeout = const Duration(seconds: 2)});
  
  /// Dispose of resources
  void dispose();
}

/// Exception thrown during OBD operations
class ObdConnectionException implements Exception {
  final String message;
  final String? deviceId;
  
  ObdConnectionException(this.message, {this.deviceId});
  
  @override
  String toString() => 'ObdConnectionException: $message${deviceId != null ? ' (device: $deviceId)' : ''}';
}
