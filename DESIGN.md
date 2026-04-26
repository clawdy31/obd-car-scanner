# Doctor Car — DESIGN.md

> OBD-II Car Scanner App for Android. Neumorphic design with dark/light theme support.

---

## 1. Brand & Identity

**App Name:** Doctor Car
**Tagline:** Your car's diagnostic companion
**Platform:** Android (Flutter)
**Design Philosophy:** Soft neumorphism — UI elements appear extruded from the background using dual shadows.

---

## 2. Color Palette

### Dark Theme (Default)
| Role | Hex | Usage |
|------|-----|-------|
| Background | `#121212` | Scaffold background |
| Surface | `#2D2D30` | Cards, sheets, containers |
| Surface Dark Shadow | `#1A1A1D` | Bottom-right shadow |
| Surface Light Shadow | `#3D3D42` | Top-left shadow |
| Accent Primary | `#E11D48` | CTA buttons, highlights |
| Accent Secondary | `#10B981` | Success, fuel, positive |
| Accent Tertiary | `#008F9C` | Coolant, intake, info |
| Text Primary | `#FFFFFF` | Headlines, values |
| Text Secondary | `#FFFFFF99` | Labels, captions |
| Text Muted | `#FFFFFF66` | Placeholders, hints |

### Light Theme
| Role | Hex | Usage |
|------|-----|-------|
| Background | `#E0E5EC` | Neumorphic base |
| Surface | `#E0E5EC` | Cards (same as bg for neumorphism) |
| Surface Dark Shadow | `#A3B1C6` | Bottom-right shadow |
| Surface Light Shadow | `#FFFFFF` | Top-left shadow |
| Accent Primary | `#E11D48` | CTA buttons, highlights |
| Text Primary | `#2D2D30` | Headlines, values |
| Text Secondary | `#666666` | Labels, captions |

---

## 3. Typography

**Font Family:** `GoogleFonts.poppins` (all weights: 400, 500, 600, 700)

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Headline Large | 32px | Bold (700) | Dashboard values (RPM, speed) |
| Headline Medium | 26px | Bold (700) | Screen titles |
| Title | 20px | SemiBold (600) | Section headers |
| Body Large | 18px | SemiBold (600) | Card titles, sensor values |
| Body | 16px | Regular (400) | Body text |
| Label | 14px | Medium (500) | Units, secondary text |
| Caption | 12px | Regular (400) | Tooltips, hints |
| Mini | 10px | Regular (400) | Scale labels |

---

## 4. Neumorphism System

### Raised Card (default state)
```dart
BoxDecoration(
  color: isDark ? Color(0xFF2D2D30) : Color(0xFFE0E5EC),
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(color: darkShadow, offset: Offset(5, 5), blurRadius: 15, spreadRadius: -2),
    BoxShadow(color: lightShadow, offset: Offset(-4, -4), blurRadius: 12, spreadRadius: -2),
  ],
)
```

### Pressed/Inset Card (active state)
```dart
boxShadow: [
  BoxShadow(color: lightShadow, offset: Offset(-3, -3), blurRadius: 8, spreadRadius: -1),
  BoxShadow(color: darkShadow.withAlpha(128), offset: Offset(3, 3), blurRadius: 8, spreadRadius: -1),
]
```

### Dark Theme Shadows
- **Light shadow:** `Color(0xFF3D3D42)`
- **Dark shadow:** `Color(0xFF1A1A1D)`

### Light Theme Shadows
- **Light shadow:** `Color(0xFFFFFFFF)`
- **Dark shadow:** `Color(0xFFA3B1C6)`

---

## 5. Component Library

### Cards

**NeumorphicCard** — Default raised card for all dashboard widgets
- Padding: 16px all sides
- Border radius: 20px (large), 16px (medium), 12px (small)
- Border: none
- Shadow: raised neumorphic (see above)

**ConnectionStatusCard** — Bluetooth/device connection status at top of dashboard
- Height: auto
- Contains: bluetooth icon + status text + animated dot

### Gauges

**ModernGaugeCard** — Large card with circular value display
- Layout: Label top, large value center, progress bar bottom
- Progress bar: 8px height, 4px border-radius, gradient fill
- Max 2 per row in a Row()

**MiniGaugeCard** — Compact sensor display
- Single-line or 2-line layout
- Icon + label top, value bottom
- Progress bar: 4px height
- Max 3 per row

**ModernLinearGauge** — Horizontal bar for tank levels
- Full width within card
- Bar height: 12px, border-radius: 6px
- Icon + label + value on same row

### Sensor Cards

**SensorCard** — Key-value display for OBD PIDs
- Icon badge (colored) top-left
- Label + info icon
- Large value below
- Max 2 per row

### Section Headers

**SectionHeader** — Groups related sensors
- Neumorphic icon badge (10px radius) + bold title
- Icon color: Accent Primary (`#E11D48`)

### Buttons

**ElevatedButton** — Primary CTA
- Background: Accent Primary (`#E11D48`)
- Text: White, Poppins 14px Medium
- Border radius: 12px
- Height: 48px
- Full-width or icon+label layout

**TextButton** — Secondary action
- Text only, Accent Primary color
- No background

**IconButton** — Toolbar actions
- Neumorphic circular button
- Size: 40-50px

### Navigation

**BottomNavBar** — 5 tabs with icons + labels
- Tabs: Dashboard, Errors, Live Data, Settings, Info
- Active: Accent Primary fill
- Inactive: Grey icon

**AppBar** — Standard Material AppBar
- Background: Surface color (dark: #1E1E1E, light: white)
- Elevation: 0
- Leading: App icon (40x40 rounded)
- Title: "Doctor Car" in Poppins Bold 18px
- Actions: Theme toggle, Bluetooth, Refresh

### Sheets

**BottomSheet** — Bluetooth device list, theme picker
- Border radius: 20px top
- Background: Surface color
- Handle bar: 40x4px, centered, grey[600]
- Padding: 20px horizontal

### Inputs

**SearchField** — Device search in bluetooth sheet
- Neumorphic inset style
- Prefix: search icon
- Hint: "Search devices..."

---

## 6. Layout System

### Spacing Scale
| Token | Value | Use |
|-------|-------|-----|
| xs | 4px | Tight spacing |
| sm | 8px | Icon gaps |
| md | 12px | Card internal gaps |
| lg | 16px | Card padding, section gaps |
| xl | 24px | Section spacing |
| xxl | 32px | Major sections |

### Grid
- Screen padding: 20px horizontal
- Card gap: 12px
- Max cards per row: 3 (mini gauges), 2 (standard cards)
- Section gap: 24px between sections

### Screen Padding
```dart
SingleChildScrollView(
  padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
)
```

---

## 7. Icons

**Icon Library:** Material Icons Rounded

| Icon | Use |
|------|-----|
| `bluetooth` / `bluetooth_connected` | Bluetooth status |
| `bluetooth_searching` | Scanning |
| `search` | Scan button |
| `refresh` | Reload data |
| `thermostat_rounded` | Coolant |
| `speed_rounded` | Speed, MAP, throttle |
| `trending_up_rounded` | Load |
| `local_gas_station_rounded` | Fuel |
| `air_rounded` | MAF |
| `tune_rounded` | STFT/LTFT |
| `water_drop_rounded` | IAT |
| `flash_on_rounded` | Ignition |
| `bolt_rounded` | Timing advance |
| `recycling_rounded` | EGR |
| `electric_bolt_rounded` | O2 sensor |
| `battery_full_rounded` | Voltage |
| `straighten_rounded` | Distance |
| `directions_car_rounded` | Trip stats |
| `dark_mode_rounded` / `light_mode_rounded` / `brightness_auto_rounded` | Theme toggle |

**Icon Sizes:**
- Section header: 16px
- Sensor card icon: 18px
- Card inline icon: 16-22px
- App bar icon: 24px
- Connection status: 22px

---

## 8. Animations & Motion

| Animation | Duration | Curve |
|-----------|----------|-------|
| Page transition | 300ms | `Curves.easeInOut` |
| Button press | 100ms | `Curves.easeIn` |
| Bottom sheet slide | 250ms | `Curves.easeOutCubic` |
| Progress bar fill | 600ms | `Curves.easeOut` |
| Pulse/glow (connected dot) | 1500ms | `Curves.easeInOut` (repeat) |

---

## 9. Dark / Light Theme Switching

**Implementation:** `ThemeProvider` with `ThemeMode.dark / .light / .system`
**Persistence:** `SharedPreferences`
**AppBar background:** `isDark ? Color(0xFF1E1E1E) : Colors.white`
**Scaffold background:** `isDark ? Color(0xFF121212) : Color(0xFFE0E5EC)`

**Toggle:** IconButton cycles through dark → light → system

---

## 10. Dashboard Layout

```
[AppBar: Doctor Car | Theme | Bluetooth | Refresh]
[ConnectionStatusCard: Bluetooth icon + status + dot]
[Section: Main Gauges]
  [GaugeCard: RPM] | [GaugeCard: Speed]
[Section: Secondary]
  [MiniGauge: Coolant] | [MiniGauge: Throttle] | [MiniGauge: Load]
[Section: Fuel System]
  [LinearGauge: Fuel Tank]
[Section: Sensors]
  [SensorCard: MAF] | [SensorCard: MAP]
[Section: Fuel & Air]
  [SensorCard: STFT] | [SensorCard: LTFT]
  [SensorCard: IAT] | [SensorCard: Fuel System]
[Section: Ignition]
  [SensorCard: Timing] | [SensorCard: EGR]
  [SensorCard: O2 U] | [SensorCard: O2 D]
[Section: Electrical]
  [SensorCard: Voltage] | [SensorCard: Rel. Throttle]
[Section: Trip]
  [SensorCard: Dist since codes] | [SensorCard: Warm-ups]
[BottomNavBar: Dashboard | Errors | Live | Settings | Info]
```

---

## 11. Bluetooth Sheet Layout

```
[Handle bar]
[Header: Bluetooth icon + "Bluetooth OBD" + status badge]
[Before Scanning tips box]  (only when disconnected)
[Row: Disconnect button]    (only when connected)
[Row: Scan Devices button]  (only when disconnected)
[Divider]
[Device list or Empty state]
  [DeviceCard: Icon + Name + ID + "Connect" badge]
```

---

## 12. OBD Sensor PIDs

| Key | Label | Unit | Color |
|-----|-------|------|-------|
| `rpm` | Engine RPM | RPM | Primary |
| `speed` | Speed | km/h | Primary |
| `coolant` | Coolant | °C | Red if >105 |
| `throttle` | Throttle | % | Primary |
| `load` | Engine Load | % | Red if >85 |
| `fuel` | Fuel Tank | % | Primary |
| `maf` | MAF Rate | g/s | Primary |
| `map` | MAP | kPa | Primary |
| `stft` | STFT | % | Green |
| `ltft` | LTFT | % | Green |
| `iat` | Intake Air Temp | °C | Teal |
| `fuel_system` | Fuel System | — | Primary |
| `timing` | Timing Adv. | ° | Primary |
| `egr` | EGR Error | % | Red |
| `o2_u` | O2 Sensor (U) | V | Green |
| `o2_d` | O2 Sensor (D) | V | Green |
| `voltage` | Module Voltage | V | Teal |
| `rel_throttle` | Rel. Throttle | % | Primary |
| `dist_codes` | Dist. Since Codes | km | Primary |
| `warmups` | Warm-ups | — | Green |

---

*Last updated: 2026-04-26*
