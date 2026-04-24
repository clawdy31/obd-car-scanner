# Clean Architecture Reference - Doctor Car App

Based on Google's Android Architecture Samples

## Project Structure

```
lib/
├── app/                          # App entry point & configuration
│   └── app.dart                  # MaterialApp setup with providers
├── core/                         # Shared utilities
│   ├── constants/               # App-wide constants
│   │   └── app_constants.dart   # Keys, timeouts, defaults
│   └── theme/                   # Theme configuration
│       └── app_theme.dart       # Colors, themes
├── data/                        # Data layer - implementations
│   ├── models/                  # Data models
│   │   └── obd_device_model.dart
│   └── repositories/            # Repository implementations
│       └── obd_repository_impl.dart
├── domain/                      # Business logic - interfaces
│   ├── entities/                # Business objects
│   │   ├── obd_reading.dart     # Sensor readings
│   │   └── vehicle_info.dart    # Vehicle data + DTCs
│   └── repositories/            # Repository interfaces
│       └── obd_repository.dart  # Contract definition
└── presentation/                # UI layer
    ├── providers/              # State management (ViewModels)
    │   └── obd_provider.dart    # ChangeNotifier-based provider
    ├── screens/                 # Full screen widgets
    │   ├── dashboard/
    │   ├── dtc/
    │   ├── live_data/
    │   └── vehicle_info/
    └── widgets/                # Reusable UI components
```

## Architecture Layers

### 1. Domain Layer (innermost - no dependencies)
**Purpose:** Business logic and rules - completely independent

- `entities/` - Business objects (ObdReading, VehicleInfo, DTC)
- `repositories/` - Abstract interfaces (ObdRepository)

**Rule:** Domain layer knows NOTHING about Flutter, data sources, or UI

### 2. Data Layer (depends on Domain)
**Purpose:** Implement repository interfaces and handle data

- `models/` - Data transfer objects (maps to JSON/DB)
- `repositories/` - Concrete implementations

**Rule:** Data layer IMPLEMENTS domain interfaces, handles serialization

### 3. Presentation Layer (depends on Domain)
**Purpose:** UI and state management

- `providers/` - ViewModels/ChangeNotifiers (state + business logic)
- `screens/` - Full page widgets
- `widgets/` - Reusable UI components

**Rule:** Presentation uses domain interfaces, never data layer directly

### 4. App Layer (orchestrates everything)
**Purpose:** Wire up dependencies, configure app

- `app.dart` - MaterialApp, providers setup, navigation

## Key Principles

### Dependency Rule
```
Presentation → Domain ← Data
         ↓              ↓
        App (wires both)
```

Dependencies only point INWARD. Domain has no dependencies.

### Repository Pattern
```dart
// Domain defines the interface (what, not how)
abstract class ObdRepository {
  Future<List<String>> getStoredDTCs();
  Future<Map<String, String>> readLiveData();
}

// Data implements it (how)
class ObdRepositoryImpl implements ObdRepository {
  // Actual Bluetooth/OBD logic here
}
```

### Provider/ViewModel Pattern
```dart
// Presentation layer - state management
class ObdProvider extends ChangeNotifier {
  List<String> _storedCodes = [];
  List<String> get storedCodes => _storedCodes;

  Future<void> refresh() async {
    // Orchestrates repository calls
    _storedCodes = await _repository.getStoredDTCs();
    notifyListeners(); // UI rebuilds
  }
}
```

## How to Use This Architecture

### Adding a new feature (e.g., fuel economy):

1. **Domain** - Create entity, add to repository interface
   - `domain/entities/fuel_economy.dart`
   - Add method to `ObdRepository`

2. **Data** - Implement repository
   - Add to `obd_repository_impl.dart`

3. **Presentation** - Create/update provider and screens
   - Add to `ObdProvider`
   - Create screen widget

4. **App** - Wire it up
   - Add to `main.dart` provider setup

## Comparison: Before vs After

### Before (Current Implementation)
```
main.dart (900+ lines)
├── Everything mixed together
├── ObdManager (connection + data + state)
├── Inline screens and widgets
└── Hard to find/change specific features
```

### After (Clean Architecture Reference)
```
lib/
├── domain/           # Pure business logic
├── data/            # Implementation details
├── presentation/    # UI only
└── app/            # Wiring
```

## Using This Reference

1. **New features** → Use clean architecture
2. **Existing code** → Works as-is (no refactor required)
3. **Gradual migration** → Copy patterns when modifying existing code

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib.dart` | Barrel file - exports all clean architecture modules |
| `app_theme.dart` | Colors, themes, gradients |
| `obd_provider.dart` | Example of proper state management |
| `obd_repository.dart` | Example of repository interface |
| `obd_repository_impl.dart` | Example of data layer implementation |