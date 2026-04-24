/// Bluetooth type enumeration
enum BluetoothType {
  classic,  // Bluetooth Classic (SPP) - HC-05, HC-06, OBDLink SX
  ble,      // Bluetooth Low Energy - BLE ELM327 dongles
}

/// Unified OBD Device model - wraps scan results from both Classic and BLE
class ObdDevice {
  /// Unique identifier (MAC address for Classic, MAC/UUID for BLE)
  final String id;
  
  /// Device display name
  final String? name;
  
  /// Bluetooth type (Classic or BLE)
  final BluetoothType type;
  
  /// Signal strength (RSSI) - available from BLE scans
  final int? rssi;
  
  /// Whether device is already paired (Classic)
  final bool isPaired;

  const ObdDevice({
    required this.id,
    this.name,
    required this.type,
    this.rssi,
    this.isPaired = false,
  });

  /// Check if this device appears to be an OBD adapter based on name
  bool get isObdAdapter {
    String n = name?.toLowerCase() ?? '';
    return n.contains('obd') ||
        n.contains('elm') ||
        n.contains('hc-0') ||
        n.contains('modaxe') ||
        n.contains('vgate') ||
        n.contains('obd2') ||
        n.contains('scanner') ||
        n.contains('diagnostic');
  }

  /// Display name with fallback
  String get displayName => name?.isNotEmpty == true ? name! : 'Unknown Device';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObdDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;

  @override
  String toString() => 'ObdDevice(id: $id, name: $name, type: $type)';
}
