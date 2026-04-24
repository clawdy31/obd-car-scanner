import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, String> liveData;
  final bool isConnected;
  final String? deviceName;

  const DashboardScreen({super.key, required this.liveData, required this.isConnected, this.deviceName});

  @override
  Widget build(BuildContext context) {
    final rpm = double.tryParse(liveData['rpm'] ?? '0') ?? 0;
    final speed = double.tryParse(liveData['speed'] ?? '0') ?? 0;
    final coolant = double.tryParse(liveData['coolant'] ?? '0') ?? 0;
    final throttle = double.tryParse(liveData['throttle'] ?? '0') ?? 0;
    final load = double.tryParse(liveData['load'] ?? '0') ?? 0;
    final fuel = double.tryParse(liveData['fuel'] ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status
          _ModernConnectionStatus(isConnected: isConnected, deviceName: deviceName),
          const SizedBox(height: 24),

          // Main Gauges Row
          Row(
            children: [
              Expanded(
                child: _ModernGaugeCard(
                  label: 'Engine RPM',
                  tooltipMsg: 'Revolutions Per Minute: How fast the engine\'s crankshaft is spinning.',
                  value: liveData['rpm'] ?? '--',
                  unit: 'RPM',
                  maxValue: 8000,
                  currentValue: rpm,
                  gradient: const [Color(0x991D7CE1), Color(0xFF008F9C)],
                  alertColor: rpm > 6000,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernGaugeCard(
                  label: 'Speed',
                  tooltipMsg: 'Vehicle Speed: How fast your car is moving in kilometers per hour.',
                  value: liveData['speed'] ?? '--',
                  unit: 'km/h',
                  maxValue: 200,
                  currentValue: speed,
                  gradient: const [Color(0x991D7CE1), Color(0xFF008F9C)],
                  alertColor: speed > 120,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Secondary Gauges Row
          Row(
            children: [
              Expanded(child: _MiniGaugeCard(label: 'Coolant', tooltipMsg: "Coolant Temp: The temperature of the fluid keeping the engine from overheating.", value: liveData['coolant'] ?? '--', unit: '°C', maxValue: 130, currentValue: coolant, color: coolant > 105 ? Colors.red : const Color(0xFF9C0000), icon: Icons.thermostat_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _MiniGaugeCard(label: 'Throttle', tooltipMsg: 'Throttle Position: How far the accelerator pedal/throttle valve is currently open.', value: liveData['throttle'] ?? '--', unit: '%', maxValue: 100, currentValue: throttle, color: const Color(0xFFE11D48), icon: Icons.speed_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _MiniGaugeCard(label: 'Load', tooltipMsg: 'Engine Load: The current mechanical stress on the engine compared to its maximum capacity.', value: liveData['load'] ?? '--', unit: '%', maxValue: 100, currentValue: load, color: load > 85 ? Colors.red : const Color(0xFFE11D48), icon: Icons.trending_up_rounded)),
            ],
          ),
          const SizedBox(height: 22),

          // Fuel Section
          _SectionHeader(title: 'Fuel System', icon: Icons.local_gas_station_rounded),
          const SizedBox(height: 12),
          _ModernLinearGauge(label: 'Fuel Tank', tooltipMsg: 'Fuel Level: The current amount of fuel in your tank as a percentage.', value: liveData['fuel'] ?? '--', unit: '%', percentage: fuel / 100),
          const SizedBox(height: 24),

          // Sensors Section
          _SectionHeader(title: 'Sensors', icon: Icons.sensors_rounded),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SensorCard(label: 'MAF Rate', tooltipMsg: 'Mass Air Flow: Measures the amount of air entering the engine to calculate fuel injection.', value: liveData['maf'] ?? '--', unit: 'g/s', icon: Icons.air_rounded, color: const Color(0xFFE11D48))),
              const SizedBox(width: 12),
              Expanded(child: _SensorCard(label: 'Engine Load', tooltipMsg: 'Engine Load: The current mechanical stress on the engine compared to its maximum capacity.', value: liveData['load'] ?? '--', unit: '%', icon: Icons.settings_rounded, color: const Color(0xFFE11D48))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernConnectionStatus extends StatelessWidget {
  final bool isConnected;
  final String? deviceName;

  const _ModernConnectionStatus({required this.isConnected, this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withAlpha(13), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.withAlpha(51) : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
              color: isConnected ? Colors.green : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? (deviceName ?? 'OBD-II Connected') : 'Disconnected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected ? 'Reading live vehicle data' : 'Tap Bluetooth icon to connect',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isConnected
                  ? [BoxShadow(color: Colors.green.withAlpha(200), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(51), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFE11D48), size: 16),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[200])),
      ],
    );
  }
}

class _ModernGaugeCard extends StatelessWidget {
  final String label;
  final String tooltipMsg;
  final String value;
  final String unit;
  final double maxValue;
  final double currentValue;
  final List<Color> gradient;
  final bool alertColor;

  const _ModernGaugeCard({
    required this.label,
    required this.tooltipMsg,
    required this.value,
    required this.unit,
    required this.maxValue,
    required this.currentValue,
    required this.gradient,
    this.alertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentValue / maxValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withAlpha(13), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),
              Tooltip(
                message: tooltipMsg,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Icon(Icons.info_outline, color: Colors.grey[600], size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: alertColor ? Colors.red : Colors.grey[200])),
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 14))),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: alertColor ? [Colors.red, Colors.orange] : [const Color(0xFFE11D48), const Color(0xFFE11D48)]),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: (alertColor ? Colors.red : const Color(0xFFE11D48)).withAlpha(128), blurRadius: 8)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              Text('${maxValue.toInt()}', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniGaugeCard extends StatelessWidget {
  final String label;
  final String tooltipMsg;
  final String value;
  final String unit;
  final double maxValue;
  final double currentValue;
  final Color color;
  final IconData icon;

  const _MiniGaugeCard({
    required this.label,
    required this.tooltipMsg,
    required this.value,
    required this.unit,
    required this.maxValue,
    required this.currentValue,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (currentValue / maxValue).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.white.withAlpha(13), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11))),
              Tooltip(
                message: tooltipMsg,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Icon(Icons.info_outline, color: Colors.grey[600], size: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey[200])),
              const SizedBox(width: 2),
              Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 11))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernLinearGauge extends StatelessWidget {
  final String label;
  final String tooltipMsg;
  final String value;
  final String unit;
  final double percentage;

  const _ModernLinearGauge({
    required this.label,
    required this.tooltipMsg,
    required this.value,
    required this.unit,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withAlpha(13), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_gas_station_rounded, color: const Color(0xFFE11D48), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[200])),
                ],
              ),
              Row(
                children: [
                  Tooltip(
                    message: tooltipMsg,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(13)),
                    ),
                    textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    child: Icon(Icons.info_outline, color: Colors.grey[600], size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[200])),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withAlpha(128), blurRadius: 6)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String tooltipMsg;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _SensorCard({
    required this.label,
    required this.tooltipMsg,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withAlpha(13), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
              Tooltip(
                message: tooltipMsg,
                triggerMode: TooltipTriggerMode.tap,
                showDuration: const Duration(seconds: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Icon(Icons.info_outline, color: Colors.grey[600], size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey[200])),
          const SizedBox(height: 4),
          Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}
