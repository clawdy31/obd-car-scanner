import 'dart:io' show Platform;

import 'bluetooth_scanner_manager_real.dart'
    if (Platform.isAndroid) 'bluetooth_scanner_manager_real.dart'
    if (Platform.isIOS) 'bluetooth_scanner_manager_ios.dart';

export 'bluetooth_scanner_manager_real.dart'
    if (Platform.isAndroid) 'bluetooth_scanner_manager_real.dart'
    if (Platform.isIOS) 'bluetooth_scanner_manager_ios.dart';

BluetoothScannerManager createBluetoothScannerManager() {
  return BluetoothScannerManager();
}
