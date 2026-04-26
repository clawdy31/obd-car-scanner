#!/usr/bin/env python3
"""Apply drawer navigation to main.dart - comprehensive clean implementation."""

with open('lib/main.dart') as f:
    content = f.read()

# ============================================================
# FIX 1: obd.refresh -> startScan
# ============================================================
content = content.replace('onPressed: obd.refresh,', 'onPressed: () => obd.startScan(),')

# ============================================================
# FIX 2: Add _scaffoldKey after _currentIndex
# ============================================================
content = content.replace(
    '  int _currentIndex = 0;\n  static const List<String>',
    '  int _currentIndex = 0;\n  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();\n  static const List<String>'
)

# ============================================================
# FIX 3: Add drawer: _AppDrawer(...) to Scaffold
# ============================================================
content = content.replace(
    "return Scaffold(\n      backgroundColor: theme.scaffoldBackgroundColor,",
    "return Scaffold(\n      key: _scaffoldKey,\n      backgroundColor: theme.scaffoldBackgroundColor,\n      drawer: _AppDrawer(\n        currentIndex: _currentIndex,\n        onItemSelected: (idx) {\n          Navigator.pop(context);\n          setState(() => _currentIndex = idx);\n        },\n      ),"
)

# ============================================================
# FIX 4: Replace title Row with leading Builder
# ============================================================
old_title = """            title: Row(
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
            ),"""

new_title = """            leading: Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/icons/app_icon.png', width: 40, height: 40),
                  ),
                ),
              ),
            ),
            title: Text('Doctor Car', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF510000))),"""

content = content.replace(old_title, new_title)

# ============================================================
# FIX 5: Remove BottomNavigationBar
# ============================================================
old_bottom_nav = """
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
  }"""

new_bottom_nav = """
    );
  }"""

content = content.replace(old_bottom_nav, new_bottom_nav)

# ============================================================
# FIX 6: Add _SettingsScreen to IndexedStack
# ============================================================
content = content.replace(
    '            _VehicleInfoScreen(vehicleInfo: obd.vehicleInfo, isConnected: obd.isConnected),\n          ],\n        ),\n      ),',
    '            _VehicleInfoScreen(vehicleInfo: obd.vehicleInfo, isConnected: obd.isConnected),\n            _SettingsScreen(),\n          ],\n        ),\n      ),'
)

# ============================================================
# FIX 7: Update _titles to include Settings
# ============================================================
content = content.replace(
    "static const List<String> _titles = ['Doctor Car', 'Errors', 'Live', 'Info'];",
    "static const List<String> _titles = ['Doctor Car', 'Errors', 'Live', 'Settings', 'Info'];"
)

# ============================================================
# FIX 8: Add _AppDrawer and _DrawerItem classes BEFORE _LiveDataScreen
# ============================================================
app_drawer_class = '''class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const _AppDrawer({required this.currentIndex, required this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final obd = context.watch<ObdManager>();

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
                    : [const Color(0xFFE11D48), const Color(0xFF9C0000)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/icons/app_icon.png', width: 40, height: 40, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Doctor Car', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('OBD Scanner', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  ])),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: obd.isConnected
                        ? const Color(0xFF10B981).withAlpha(51)
                        : Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(obd.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      obd.isConnected ? 'Connected to \${obd.connectedDeviceName ?? "OBD"}' : 'Not Connected',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(children: [
                _DrawerItem(icon: Icons.dashboard_rounded, label: 'Dashboard', isSelected: currentIndex == 0, onTap: () => onItemSelected(0)),
                _DrawerItem(icon: Icons.error_outline_rounded, label: 'Errors', isSelected: currentIndex == 1, badgeCount: obd.storedCodes.length, onTap: () => onItemSelected(1)),
                _DrawerItem(icon: Icons.show_chart_rounded, label: 'Live Data', isSelected: currentIndex == 2, onTap: () => onItemSelected(2)),
                const Divider(),
                _DrawerItem(icon: Icons.settings_rounded, label: 'Settings', isSelected: currentIndex == 3, onTap: () => onItemSelected(3)),
                _DrawerItem(icon: Icons.info_outline_rounded, label: 'Info', isSelected: currentIndex == 4, onTap: () => onItemSelected(4)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.isSelected, this.badgeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white.withAlpha(13) : const Color(0xFFFDE7EF)) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 22, color: isSelected ? const Color(0xFFE11D48) : (isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isDark ? Colors.white : Colors.black87))),
            if (badgeCount != null && badgeCount! > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(10)),
              child: Text('\$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

'''

content = content.replace(
    'class _LiveDataScreen extends StatelessWidget',
    app_drawer_class + 'class _LiveDataScreen extends StatelessWidget'
)

# ============================================================
# FIX 9: Add _SettingsScreen class BEFORE _HelperStep
# ============================================================
settings_screen_class = '''class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFD7E5),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF121212), Color(0xFF121212)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD7E5), Color(0xFFFFD7E5)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : const Color(0xFF510000)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('Settings', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF510000))),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _SettingsSection(title: 'Appearance', children: [
                      _SettingsTile(icon: Icons.dark_mode_rounded, title: 'Theme', subtitle: 'Change app theme', trailing: Consumer<ThemeProvider>(
                        builder: (context, theme, _) => Switch(
                          value: theme.themeMode == ThemeMode.dark,
                          onChanged: (_) => _showThemeSheet(context),
                          activeColor: const Color(0xFFE11D48),
                        ),
                      )),
                    ]),
                    const SizedBox(height: 16),
                    _SettingsSection(title: 'Connection', children: [
                      _SettingsTile(icon: Icons.bluetooth_rounded, title: 'Bluetooth', subtitle: 'Manage OBD connection', trailing: const Icon(Icons.chevron_right)),
                    ]),
                    const SizedBox(height: 16),
                    _SettingsSection(title: 'About', children: [
                      _SettingsTile(icon: Icons.info_outline_rounded, title: 'About Doctor Car', subtitle: 'Version 1.0.0', trailing: const Icon(Icons.chevron_right)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Choose Theme', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ThemeTile(title: 'Light Mode', icon: Icons.light_mode_rounded, mode: ThemeMode.light),
          _ThemeTile(title: 'Dark Mode', icon: Icons.dark_mode_rounded, mode: ThemeMode.dark),
          _ThemeTile(title: 'System Default', icon: Icons.brightness_auto_rounded, mode: ThemeMode.system),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600], letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFE11D48).withAlpha(26), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFFE11D48), size: 20),
      ),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      trailing: trailing,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode mode;

  const _ThemeTile({required this.title, required this.icon, required this.mode});

  @override
  Widget build(BuildContext context) {
    final currentMode = context.read<ThemeProvider>().themeMode;
    final isSelected = currentMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFFE11D48) : null),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFFE11D48)) : null,
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }
}

'''

content = content.replace(
    'class _HelperStep extends StatelessWidget',
    settings_screen_class + 'class _HelperStep extends StatelessWidget'
)

with open('lib/main.dart', 'w') as f:
    f.write(content)

print("All fixes applied successfully")
print(f"Final line count: {len(content.splitlines())}")
