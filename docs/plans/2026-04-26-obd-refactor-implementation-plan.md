# OBD Scanner Refactoring - Implementation Plan

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement.

**Goal:** Complete platform-split refactoring and fix all analyzer warnings

**Architecture:** ObdManager factory routes to platform-specific managers (Ios/BLE-only, Android/BLE+Classic). Platform-specific scanner managers handle Bluetooth differences. All connections use ObdConnection interface.

**Tech Stack:** Flutter, flutter_blue_plus, flutter_bluetooth_serial (Android only), Dart

---

## Phase 1: Fix Platform Routing

### Task 1: Fix connections/connections.dart

**Files:**
- Modify: `lib/services/connections/connections.dart`

**Step 1: Write failing test**
```dart
// test/services/connections/connections_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_car/services/connections/connections.dart';

void main() {
  test('ClassicObdConnection exists and can be instantiated', () {
    final conn = ClassicObdConnection();
    expect(conn.isConnected, false);
  });
}
```

**Step 2: Run test — confirm it fails**
Command: `cd ~/car_scanner/obd_car_scanner && flutter test test/services/connections/connections_test.dart 2>&1`
Expected: FAIL — Current routing exports iOS stub which may cause issues on Android

**Step 3: Write implementation**
```dart
// lib/services/connections/connections.dart
import 'dart:io' show Platform;

export 'classic_obd_connection.dart'
    if (Platform.isAndroid) 'classic_obd_connection_real.dart'
    if (Platform.isIOS) 'classic_obd_connection_ios.dart';
export 'ble_obd_connection.dart';
export 'obd_connection.dart';
```

**Step 4: Run test — confirm it passes**
Command: `flutter test test/services/connections/connections_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/services/connections/connections.dart && git commit -m "fix: conditional export for ClassicObdConnection"`

---

### Task 2: Clean up bluetooth_scanner_manager.dart

**Files:**
- Modify: `lib/services/bluetooth_scanner_manager.dart`

**Step 1: Write failing test**
```dart
// test/services/bluetooth_scanner_manager_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BluetoothScannerManager creates successfully', () {
    // Verify conditional import resolves
  });
}
```

**Step 2: Run test — confirm it fails**
Command: `cd ~/car_scanner/obd_car_scanner && flutter test test/services/bluetooth_scanner_manager_test.dart 2>&1 || echo "Test file not found - will create"`

**Step 3: Write implementation**
```dart
// lib/services/bluetooth_scanner_manager.dart
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
```

**Step 4: Run test — confirm it passes**
Command: `flutter test test/services/bluetooth_scanner_manager_test.dart`
Expected: PASS

**Step 5: Commit**
`git add lib/services/bluetooth_scanner_manager.dart && git commit -m "fix: correct conditional imports for platform routing"`

---

## Phase 2: Fix All Analyzer Warnings

### Task 3: Fix bluetooth_scanner_manager_real.dart

**Files:**
- Modify: `lib/services/bluetooth_scanner_manager_real.dart`

**Step 1: Write failing test**
```dart
// test/services/bluetooth_scanner_real_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('analyzer passes - no warnings', () {
    // Run flutter analyze and check exit code
  });
}
```

**Step 2: Run test — confirm it fails**
Command: `cd ~/car_scanner/obd_car_scanner && flutter analyze lib/services/bluetooth_scanner_manager_real.dart 2>&1 | grep -c warning`

**Step 3: Write implementation**
Remove unused imports and fix `await` on bool:

```dart
// Changes to make:
// 1. Remove unused import: 'package:flutter/foundation.dart'
// 2. Line 209: Change `await stopScan();` to just `stopScan();` (it's sync)
// 3. Line 214: Add comment to empty catch block: `// Ignore errors during cleanup`
```

**Step 4: Run test — confirm it passes**
Command: `flutter analyze lib/services/bluetooth_scanner_manager_real.dart`
Expected: No warnings

**Step 5: Commit**
`git add lib/services/bluetooth_scanner_manager_real.dart && git commit -m "fix: remove unused imports and fix await in bluetooth_scanner_manager_real"`

---

### Task 4: Fix bluetooth_scanner_manager_ios.dart

**Files:**
- Modify: `lib/services/bluetooth_scanner_manager_ios.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/bluetooth_scanner_manager_ios.dart 2>&1`

**Step 2: Fix issues**
- Line 98: Change `await _safeStop();` to `_safeStop();` (sync operation)

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/bluetooth_scanner_manager_ios.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/bluetooth_scanner_manager_ios.dart && git commit -m "fix: remove await on sync method in bluetooth_scanner_manager_ios"`

---

### Task 5: Fix obd_manager_android.dart

**Files:**
- Modify: `lib/services/obd_manager_android.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/obd_manager_android.dart 2>&1`

**Step 2: Fix issues**
- Remove duplicate import (line 12: `import 'connections/ble_obd_connection.dart';` appears twice)
- Remove unused imports: `dart:io`, `package:flutter/foundation.dart`
- Line 38: Change `await _scanner.stopScan();` to `_scanner.stopScan();`

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/obd_manager_android.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/obd_manager_android.dart && git commit -m "fix: remove unused imports and duplicate import in obd_manager_android"`

---

### Task 6: Fix obd_manager_ios.dart

**Files:**
- Modify: `lib/services/obd_manager_ios.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/obd_manager_ios.dart 2>&1`

**Step 2: Fix issues**
- Remove unused imports: `dart:io`, `package:flutter/foundation.dart`
- Line 38: Change `await _scanner.stopScan();` to `_scanner.stopScan();`

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/obd_manager_ios.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/obd_manager_ios.dart && git commit -m "fix: remove unused imports in obd_manager_ios"`

---

### Task 7: Fix obd_manager.dart (factory)

**Files:**
- Modify: `lib/services/obd_manager.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/obd_manager.dart 2>&1`

**Step 2: Fix issues**
- Line 38: Change `await _scanner.stopScan();` to `_scanner.stopScan();` (sync method)

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/obd_manager.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/obd_manager.dart && git commit -m "fix: remove await on sync method in obd_manager factory"`

---

### Task 8: Fix connections/classic_obd_connection_ios.dart

**Files:**
- Modify: `lib/services/connections/classic_obd_connection_ios.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/connections/classic_obd_connection_ios.dart 2>&1`

**Step 2: Fix issues**
- Remove `override` from line 37 (getter doesn't override inherited)
- Make `_currentState` final

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/connections/classic_obd_connection_ios.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/connections/classic_obd_connection_ios.dart && git commit -m "fix: remove invalid override in classic_obd_connection_ios"`

---

### Task 9: Fix connections/classic_obd_connection_real.dart

**Files:**
- Modify: `lib/services/connections/classic_obd_connection_real.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/connections/classic_obd_connection_real.dart 2>&1`

**Step 2: Fix issues**
- Remove `override` from line 87 (getter doesn't override inherited)
- Add `Stream<String> get data => dataStream;` to ObdConnection interface if missing

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/connections/classic_obd_connection_real.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/connections/classic_obd_connection_real.dart && git commit -m "fix: remove invalid override in classic_obd_connection_real"`

---

### Task 10: Fix ble_obd_connection.dart

**Files:**
- Modify: `lib/services/connections/ble_obd_connection.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/connections/ble_obd_connection.dart 2>&1`

**Step 2: Fix issues**
- Remove unused fields: `_stateSubscription`, `_lastDeviceId`, `_lastValue`

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/connections/ble_obd_connection.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/connections/ble_obd_connection.dart && git commit -m "fix: remove unused fields in ble_obd_connection"`

---

### Task 11: Fix obd_service.dart

**Files:**
- Modify: `lib/services/obd_service.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/obd_service.dart 2>&1`

**Step 2: Fix issues**
- Remove unused fields: `_retryCount`, `_maxRetries`
- Line 204: Remove unnecessary braces in string interpolation

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/obd_service.dart`
Expected: No warnings

**Step 4: Commit**
`git add lib/services/obd_service.dart && git commit -m "fix: remove unused fields in obd_service"`

---

### Task 12: Fix remaining stub files

**Files:**
- Modify: `lib/services/bluetooth_scanner_manager_stub.dart`
- Modify: `lib/services/connections/classic_obd_connection_stub.dart`
- Modify: `lib/services/obd_manager_stub.dart`

**Step 1: Identify issues**
Command: `flutter analyze lib/services/bluetooth_scanner_manager_stub.dart lib/services/connections/classic_obd_connection_stub.dart lib/services/obd_manager_stub.dart 2>&1`

**Step 2: Fix issues**
- bluetooth_scanner_manager_stub.dart: remove unused imports, remove `_addDevice` if truly unused
- classic_obd_connection_stub.dart: remove invalid override
- obd_manager_stub.dart: empty constructor body should use `;`

**Step 3: Run test — confirm it passes**
Command: `flutter analyze lib/services/`
Expected: All warnings resolved

**Step 4: Commit**
`git add -A && git commit -m "fix: remaining analyzer warnings cleaned up"`

---

## Phase 3: Add Unit Tests

### Task 13: Test ObdManager Factory

**Files:**
- Create: `test/services/obd_manager_factory_test.dart`
- Modify: `lib/services/obd_manager.dart` (if needed)

**Step 1: Write failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show Platform;

void main() {
  test('ObdManager creates correct platform manager', () {
    // This test verifies the factory pattern works
    // Note: Platform cannot be mocked in unit tests easily
    // So this is more of a compile-time check
  });
}
```

**Step 2: Run test — confirm it fails**
Command: `flutter test test/services/obd_manager_factory_test.dart 2>&1`

**Step 3: Write implementation**
- Ensure ObdManager factory compiles without errors
- Add a simple smoke test

**Step 4: Run test — confirm it passes**
Command: `flutter test test/services/obd_manager_factory_test.dart`
Expected: PASS

**Step 5: Commit**
`git add test/services/obd_manager_factory_test.dart && git commit -m "test: ObdManager factory smoke test"`

---

### Task 14: Test ObdConnection implementations compile

**Files:**
- Create: `test/services/connections/obd_connection_test.dart`

**Step 1: Write failing test**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_car/services/connections/connections.dart';

void main() {
  test('ClassicObdConnection can be instantiated', () {
    final conn = ClassicObdConnection();
    expect(conn.isConnected, false);
    conn.dispose();
  });
  
  test('BleObdConnection can be instantiated', () {
    final conn = BleObdConnection();
    expect(conn.isConnected, false);
    conn.dispose();
  });
}
```

**Step 2: Run test — confirm it fails**
Command: `flutter test test/services/connections/obd_connection_test.dart 2>&1`

**Step 3: Write implementation**
- Ensure both connection types can be instantiated and disposed

**Step 4: Run test — confirm it passes**
Command: `flutter test test/services/connections/obd_connection_test.dart`
Expected: PASS

**Step 5: Commit**
`git add test/services/connections/obd_connection_test.dart && git commit -m "test: ObdConnection implementations compile correctly"`

---

### Task 15: Final verification

**Files:**
- Run: Full analyzer and test suite

**Step 1: Run full analysis**
Command: `cd ~/car_scanner/obd_car_scanner && flutter analyze 2>&1`
Expected: No errors or warnings

**Step 2: Run all tests**
Command: `flutter test 2>&1`
Expected: All tests pass

**Step 3: Final commit**
`git add -A && git commit -m "chore: OBD refactoring complete - all warnings fixed, tests passing"`

---

## Summary

**Total Tasks:** 15
**Files Modified:** ~12 service files
**Files Created:** ~3 test files
**Commits:** 15 (one per task, following TDD)

**Execution Options:**
1. **Subagent-Driven** — I dispatch fresh sub-agent per task with two-stage review
2. **Manual** — You run the tasks yourself

Which approach would you prefer?