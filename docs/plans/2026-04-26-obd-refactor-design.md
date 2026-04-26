# OBD Scanner Refactoring Design

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement.

**Date:** 2026-04-26

**Goal:** Complete the platform-split refactoring and fix all analyzer warnings. Two-phase approach: (1) fix platform routing, (2) add unit tests for platform-specific managers.

**Architecture:** 
- `ObdManager` (factory) creates `ObdManagerIos` or `ObdManagerAndroid` at runtime based on `Platform.isIOS/Android`
- iOS uses BLE-only; Android supports both Classic Bluetooth (SPP) and BLE
- Platform-specific scanner managers handle Bluetooth differences
- All connections use the `ObdConnection` interface

**Tech Stack:** Flutter, flutter_blue_plus, flutter_bluetooth_serial (Android only), Dart

---

## Phase 1: Design Review

### Question 1: iOS Classic Bluetooth Handling
The `classic_obd_connection.dart` exports to iOS stub, but Android also needs to route to `classic_obd_connection_real.dart`. How should we handle this?

**Current structure:**
```dart
// connections/connections.dart
export 'classic_obd_connection.dart';  // Only exports iOS stub for now
```

**Proposed fix:** Use conditional exports properly for both platforms.

---

### Question 2: BluetoothScannerManager Routing
The `bluetooth_scanner_manager.dart` uses conditional imports but also has platform-specific files (`_ios.dart`, `_real.dart`, `_stub.dart`). Need to verify the routing is correct.

---

### Question 3: Stub Files
Some stub files exist (`_stub.dart`) but aren't being used effectively. Should they be:
- **Option A:** Removed (not needed since platform variants cover everything)
- **Option B:** Kept as fallback (for web/fallback scenarios)

---

**My recommendation for all three:**
1. Fix `connections/connections.dart` to use conditional exports for both platforms
2. Verify `bluetooth_scanner_manager.dart` routing
3. Keep stubs but clean up unused ones

**Is this approach acceptable?** Yes → proceed to write full plan. No → clarify what's different.