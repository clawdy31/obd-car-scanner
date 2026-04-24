import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)];
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }
}

class StatusDot extends StatelessWidget {
  final bool isConnected;
  final String? label;
  const StatusDot({super.key, required this.isConnected, this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
            boxShadow: [BoxShadow(color: (isConnected ? Colors.green : Colors.red).withAlpha(128), blurRadius: 6, spreadRadius: 2)],
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(label!, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ],
    );
  }
}

class LinearGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double percentage;
  final Color? barColor;
  const LinearGauge({super.key, required this.label, required this.value, required this.unit, required this.percentage, this.barColor});

  @override
  Widget build(BuildContext context) {
    Color color = barColor ?? Colors.green;
    if (percentage < 0.1) color = Colors.red;
    else if (percentage < 0.25) color = Colors.orange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('$value $unit', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 20,
          ),
        ),
      ],
    );
  }
}

class DataCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color? valueColor;
  const DataCard({super.key, required this.label, required this.value, this.unit, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: Colors.grey[500], size: 20)]),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white)),
                if (unit != null) Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(unit!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class GaugeWidget extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double minValue;
  final double maxValue;
  final double percentage;
  final Color color;

  const GaugeWidget({super.key, required this.label, required this.value, required this.unit, required this.minValue, required this.maxValue, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 170,
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: GaugePainter(percentage: percentage, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[300]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5, false, bgPaint);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.75, math.pi * 1.5 * percentage.clamp(0.0, 1.0), false, valuePaint);
  }

  @override
  bool shouldRepaint(GaugePainter old) => old.percentage != percentage || old.color != color;
}

class MiniGauge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double percentage;
  final Color color;

  const MiniGauge({super.key, required this.label, required this.value, required this.unit, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 120,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(unit, style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
