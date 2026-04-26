import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_car/services/models/obd_device.dart';

void main() {
  group('ObdDevice', () {
    group('creation', () {
      test('creates instance with required id and type', () {
        const device = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );

        expect(device.id, 'AA:BB:CC:DD:EE:FF');
        expect(device.type, BluetoothType.classic);
        expect(device.name, isNull);
        expect(device.rssi, isNull);
        expect(device.isPaired, false);
      });

      test('creates instance with all fields', () {
        final device = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'HC-05',
          type: BluetoothType.classic,
          rssi: -45,
          isPaired: true,
        );

        expect(device.name, 'HC-05');
        expect(device.rssi, -45);
        expect(device.isPaired, true);
      });
    });

    group('isObdAdapter', () {
      test('returns true for OBD in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'OBD Scanner',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for ELM in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'BLE ELM327',
          type: BluetoothType.ble,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for HC-05 in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'HC-05',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for HC-06 in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'HC-06',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for VGate in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'VGate BLE',
          type: BluetoothType.ble,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for OBD2 in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'OBD2 Adapter',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for scanner in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'Car Scanner',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for diagnostic in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'Diagnostic Tool',
          type: BluetoothType.ble,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for modaxe in name', () {
        const device = ObdDevice(
          id: '123',
          name: 'Modaxe OBD',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns true for case-insensitive matches', () {
        const device = ObdDevice(
          id: '123',
          name: 'elm327',
          type: BluetoothType.ble,
        );
        expect(device.isObdAdapter, true);
      });

      test('returns false for non-OBD device names', () {
        const device = ObdDevice(
          id: '123',
          name: 'iPhone',
          type: BluetoothType.ble,
        );
        expect(device.isObdAdapter, false);
      });

      test('returns false when name is null', () {
        const device = ObdDevice(
          id: '123',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, false);
      });

      test('returns false when name is empty', () {
        final device = ObdDevice(
          id: '123',
          name: '',
          type: BluetoothType.classic,
        );
        expect(device.isObdAdapter, false);
      });
    });

    group('displayName', () {
      test('returns name when present and non-empty', () {
        const device = ObdDevice(
          id: '123',
          name: 'HC-05',
          type: BluetoothType.classic,
        );
        expect(device.displayName, 'HC-05');
      });

      test('returns "Unknown Device" when name is null', () {
        const device = ObdDevice(
          id: '123',
          type: BluetoothType.classic,
        );
        expect(device.displayName, 'Unknown Device');
      });

      test('returns "Unknown Device" when name is empty', () {
        final device = ObdDevice(
          id: '123',
          name: '',
          type: BluetoothType.classic,
        );
        expect(device.displayName, 'Unknown Device');
      });
    });

    group('equality', () {
      test('devices with same id and type are equal', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );

        expect(device1 == device2, true);
      });

      test('devices with different id are not equal', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: '11:22:33:44:55:66',
          type: BluetoothType.classic,
        );

        expect(device1 == device2, false);
      });

      test('devices with same id but different type are not equal', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.ble,
        );

        expect(device1 == device2, false);
      });

      test('name is not considered in equality', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'HC-05',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'Different Name',
          type: BluetoothType.classic,
        );

        expect(device1 == device2, true);
      });

      test('rssi and isPaired are not considered in equality', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
          rssi: -45,
          isPaired: true,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
          rssi: -80,
          isPaired: false,
        );

        expect(device1 == device2, true);
      });
    });

    group('hashCode', () {
      test('equal objects have same hashCode', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );

        expect(device1.hashCode, device2.hashCode);
      });

      test('different id produces different hashCode', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: '11:22:33:44:55:66',
          type: BluetoothType.classic,
        );

        expect(device1.hashCode != device2.hashCode, true);
      });

      test('different type produces different hashCode', () {
        const device1 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );
        const device2 = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.ble,
        );

        expect(device1.hashCode != device2.hashCode, true);
      });

      test('hashCode is stable across multiple calls', () {
        const device = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          type: BluetoothType.classic,
        );

        expect(device.hashCode, device.hashCode);
        expect(device.hashCode, device.hashCode);
      });
    });

    group('toString', () {
      test('returns expected format', () {
        const device = ObdDevice(
          id: 'AA:BB:CC:DD:EE:FF',
          name: 'HC-05',
          type: BluetoothType.classic,
        );

        expect(
          device.toString(),
          'ObdDevice(id: AA:BB:CC:DD:EE:FF, name: HC-05, type: BluetoothType.classic)',
        );
      });
    });
  });
}