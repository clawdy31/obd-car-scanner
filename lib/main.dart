import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dtc_screen.dart';
import 'widgets/common_widgets.dart';
import 'services/obd_manager.dart';
import 'services/models/obd_device.dart';
import 'services/bluetooth_scanner_manager.dart';
import 'services/obd_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  runApp(const CarScannerApp());
}

class CarScannerApp extends StatelessWidget {
  const CarScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final manager = ObdManager();
        manager.initialize(); // fire and forget, non-blocking
        return manager;
      },
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'Doctor Car',
              debugShowCheckedModeBanner: false,
              themeMode: themeProvider.themeMode,
              darkTheme: _buildDarkTheme(),
              theme: _buildLightTheme(),
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1E1E1E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB8E4C0),
        secondary: Color(0xFF1E1E1E),
        tertiary: Color(0xFF9AAE8B),
        surface: Color(0xFF1E1E1E),
        error: Color(0xFFA2EF44),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFE11D48),
      scaffoldBackgroundColor: const Color(0xFFFFD7E5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE11D48),
        secondary: Color(0xFF9C0000),
        tertiary: Color(0xFFE11D48),
        surface: Colors.white,
        error: Color(0xFFEF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF510000)),
        iconTheme: IconThemeData(color: Color(0xFF510000)),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(bodyColor: const Color(0xFF510000), displayColor: const Color(0xFF510000)),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  static const List<String> _titles = ['Doctor Car', 'Errors', 'Live', 'Info'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final obd = context.watch<ObdManager>();
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(38), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Doctor Car', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(
                icon: Consumer<ThemeProvider>(
                  builder: (context, theme, _) => Icon(
                    theme.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : theme.themeMode == ThemeMode.light
                            ? Icons.light_mode_rounded
                            : Icons.brightness_auto_rounded,
                    color: isDark ? Colors.white : const Color(0xFF6B6B6B),
                  ),
                ),
                onPressed: () => _showThemeSheet(context),
              ),
              IconButton(
                icon: Icon(obd.isConnected ? Icons.bluetooth_connected : Icons.bluetooth, color: obd.isConnected ? const Color(0xFFE11D48) : (isDark ? Colors.white : const Color(0xFF6B6B6B))),
                onPressed: () => _showBluetoothSheet(context),
              ),
              if (obd.isConnected)
                IconButton(
                  icon: Icon(Icons.refresh, color: isDark ? Colors.white : const Color(0xFF6B6B6B)),
                  onPressed: obd.refresh,
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121212), Color(0xFF121212)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFD7E5), Color(0xFFFFD7E5)],
                ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardScreen(liveData: obd.liveData, isConnected: obd.isConnected, deviceName: obd.connectedDeviceName),
            DtcScreen(storedCodes: obd.storedCodes, isConnected: obd.isConnected, onClearCodes: () async {
              bool success = await obd.clearDTCs();
              return success;
            }),
            _LiveDataScreen(obd: obd),
            _VehicleInfoScreen(vehicleInfo: obd.vehicleInfo, isConnected: obd.isConnected),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(76), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(icon: Icons.dashboard_rounded, label: 'Dashboard', iconAsset: '📊', isSelected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavBarItem(icon: Icons.error_outline_rounded, label: 'Errors', iconAsset: '⚠️', isSelected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1), badgeCount: obd.storedCodes.length),
                _NavBarItem(icon: Icons.show_chart_rounded, label: 'Live', iconAsset: '📈', isSelected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavBarItem(icon: Icons.info_outline_rounded, label: 'Info', iconAsset: 'ℹ️', isSelected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBluetoothSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BluetoothSheet(),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = context.read<ThemeProvider>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 24, offset: const Offset(0, -6)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('App Theme', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF510000))),
              const SizedBox(height: 20),
              _ThemeOption(icon: Icons.brightness_auto_rounded, title: 'System', subtitle: 'Follow device settings', isSelected: theme.themeMode == ThemeMode.system, onTap: () { theme.setThemeMode(ThemeMode.system); Navigator.pop(ctx); }),
              _ThemeOption(icon: Icons.light_mode_rounded, title: 'Light', subtitle: 'Always use light mode', isSelected: theme.themeMode == ThemeMode.light, onTap: () { theme.setThemeMode(ThemeMode.light); Navigator.pop(ctx); }),
              _ThemeOption(icon: Icons.dark_mode_rounded, title: 'Dark', subtitle: 'Always use dark mode', isSelected: theme.themeMode == ThemeMode.dark, onTap: () { theme.setThemeMode(ThemeMode.dark); Navigator.pop(ctx); }),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.icon, required this.title, required this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE11D48).withAlpha(26) : Colors.grey.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFE11D48) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFE11D48) : (isDark ? Colors.white70 : Colors.black54)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF510000))),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
            ])),
            if (isSelected) Icon(Icons.check_circle, color: const Color(0xFFE11D48)),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;

  const _NavBarItem({required this.icon, required this.label, required this.iconAsset, required this.isSelected, required this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00ACC1).withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00ACC1).withAlpha(51) : (isDark ? Colors.grey.withAlpha(26) : Colors.grey.withAlpha(13)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(iconAsset, style: const TextStyle(fontSize: 18)),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(right: -4, top: -4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
            ]),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(
              color: isSelected ? const Color(0xFF00ACC1) : (isDark ? Colors.grey : Colors.grey[600]),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

class _HelperStep extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelperStep({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFF9C0000).withAlpha(51), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF9C0000), size: 14),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 12))),
    ]);
  }
}

class _BluetoothSheet extends StatefulWidget {
  const _BluetoothSheet({super.key});

  @override
  State<_BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<_BluetoothSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ObdManager>(
      builder: (context, obd, _) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Container(
          height: math.min(screenHeight * 0.6, 500.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 24, offset: const Offset(0, -6)),
            ],
          ),
          child: Column(children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE11D48).withAlpha(26), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bluetooth, color: Color(0xFFE11D48))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bluetooth OBD', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF510000))),
                  Text(obd.statusMessage, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ])),
                if (obd.isConnected) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(51), borderRadius: BorderRadius.circular(20)),
                  child: Text('Connected', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 12)),
                ),
              ]),
            ),
            if (!obd.isConnected) Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48).withAlpha(13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE11D48).withAlpha(26)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Before Scanning:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE11D48))),
                const SizedBox(height: 12),
                Row(children: [const _HelperStep(icon: Icons.power, text: 'Plug in OBD adapter'), const SizedBox(width: 16), const _HelperStep(icon: Icons.vpn_key, text: 'Turn ignition ON')]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                if (obd.isConnected)
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    onPressed: () async {
                      await obd.disconnect();
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: Text('Disconnect', style: GoogleFonts.poppins()),
                  ))
                else ...[
                  Expanded(child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
                    onPressed: obd.isScanning ? null : () => obd.scanForDevices(),
                    icon: Icon(obd.isScanning ? Icons.hourglass_empty : Icons.search),
                    label: Text(obd.isScanning ? 'Scanning...' : 'Scan Devices', style: GoogleFonts.poppins()),
                  )),
                  if (obd.isScanning) ...[
                    const SizedBox(width: 12),
                    IconButton(onPressed: () => obd.stopScan(), icon: const Icon(Icons.close), style: IconButton.styleFrom(backgroundColor: Colors.grey.withAlpha(51))),
                  ],
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: obd.discoveredDevices.isEmpty
                  ? _BluetoothEmptyState(isScanning: obd.isScanning)
                  : ListView.builder(
                      key: const ValueKey('device-list'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: obd.discoveredDevices.length,
                      itemBuilder: (context, index) {
                        final device = obd.discoveredDevices[index];
                        return _DeviceListItem(
                          device: device,
                          isDark: isDark,
                          onTap: () => obd.connectToDevice(device),
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }
}

// ============================================================
// POLISH: Extracted list items per vercel-react-native-skills
// list-performance-item-memo — pass primitives not objects
// list-performance-inline-objects — use const constructors
// ============================================================

class _BluetoothEmptyState extends StatelessWidget {
  final bool isScanning;
  const _BluetoothEmptyState({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            isScanning ? 'Searching for devices...' : 'No Devices Found',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan Devices" to find your OBD adapter',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _DeviceListItem extends StatelessWidget {
  final ObdDevice device;
  final bool isDark;
  final VoidCallback onTap;
  const _DeviceListItem({
    required this.device,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A2A)
              : Colors.grey.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withAlpha(26)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00ACC1).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bluetooth, color: Color(0xFF00ACC1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('OBD', style: GoogleFonts.poppins(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    device.type == BluetoothType.classic ? 'Classic' : 'BLE',
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
                  ),
                ]),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[600]),
        ]),
      ),
    );
  }
}

class _LiveDataScreen extends StatelessWidget {
  final ObdManager obd;
  const _LiveDataScreen({required this.obd});

  @override
  Widget build(BuildContext context) {
    if (!obd.isConnected) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 16),
        Text('Not Connected', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Connect to your OBD adapter to see live data', style: GoogleFonts.poppins(color: Colors.grey[500])),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Live Data', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Real-time PID values from your vehicle', style: GoogleFonts.poppins(color: Colors.grey[500])),
        const SizedBox(height: 20),
        ...obd.liveData.entries.map((entry) => _DataRow(label: entry.key.toUpperCase(), value: entry.value)),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFE11D48) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[700])),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF9C0000))),
        ],
      ),
    );
  }
}

class _VehicleInfoScreen extends StatelessWidget {
  final VehicleInfo vehicleInfo;
  final bool isConnected;
  const _VehicleInfoScreen({required this.vehicleInfo, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.info_outline, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 16),
        Text('No Vehicle Info', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Connect to your OBD adapter to read vehicle info', style: GoogleFonts.poppins(color: Colors.grey[500])),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Vehicle Information', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Text('VIN, calibration and ECU details', style: GoogleFonts.poppins(color: Colors.grey[500])),
        const SizedBox(height: 20),
        _InfoCard(label: 'VIN', value: vehicleInfo.vin.isNotEmpty ? vehicleInfo.vin : 'N/A'),
        _InfoCard(label: 'Calibration ID', value: vehicleInfo.calibrationId.isNotEmpty ? vehicleInfo.calibrationId : 'N/A'),
        _InfoCard(label: 'ECU Name', value: vehicleInfo.ecuName.isNotEmpty ? vehicleInfo.ecuName : 'N/A'),
        _InfoCard(label: 'Protocol', value: vehicleInfo.obdStandard.isNotEmpty ? vehicleInfo.obdStandard : 'Auto-detected'),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFFE11D48) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withAlpha(13) : Colors.grey.withAlpha(26)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE11D48).withAlpha(26), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.info_outline, color: Color(0xFFE11D48), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        ])),
      ]),
    );
  }
}