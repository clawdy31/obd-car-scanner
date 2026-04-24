/// Data model for discovered Bluetooth OBD devices
class ObdDeviceModel {
  final String id;
  final String name;
  final BluetoothType type;
  final int? rssi;
  final bool isConnected;

  ObdDeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.rssi,
    this.isConnected = false,
  });

  factory ObdDeviceModel.fromScanResult(dynamic result, BluetoothType type) {
    return ObdDeviceModel(
      id: result.toString(),
      name: result.name ?? 'Unknown OBD',
      type: type,
      rssi: result.rssi,
    );
  }

  ObdDeviceModel copyWith({
    String? id,
    String? name,
    BluetoothType? type,
    int? rssi,
    bool? isConnected,
  }) {
    return ObdDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() => 'ObdDevice(name: $name, type: $type)';
}

/// Bluetooth connection type
enum BluetoothType { classic, ble }