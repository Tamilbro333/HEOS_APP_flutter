// ==========================================
// FILE: lib/models/energy_data.dart
// ==========================================
class EnergyData {
  final double solarVoltage;
  final double solarPower;
  final double ebVoltage;
  final double ebCurrent;
  final double ebPower;
  final DateTime timestamp;

  EnergyData({
    required this.solarVoltage,
    required this.solarPower,
    required this.ebVoltage,
    required this.ebCurrent,
    required this.ebPower,
  }) : timestamp = DateTime.now();

  double get solarCurrent => solarVoltage > 0 ? solarPower / solarVoltage : 0.0;
  
  @override
  String toString() {
    return 'Solar: ${solarVoltage.toStringAsFixed(2)}V, ${solarPower.toStringAsFixed(2)}W | '
           'EB: ${ebVoltage.toStringAsFixed(2)}V, ${ebCurrent.toStringAsFixed(2)}A, ${ebPower.toStringAsFixed(2)}W';
  }
}

class PowerLineData {
  final String name;
  final double currentUsage;
  final double voltageUsage;
  final double power;
  final double usedPercentage;
  final bool isActive;

  PowerLineData({
    required this.name,
    required this.currentUsage,
    required this.voltageUsage,
    required this.power,
    required this.usedPercentage,
    required this.isActive,
  });

  double get dependency => usedPercentage;
}

class HistoryItem {
  final String lineName;
  final String timestamp;
  final bool isActive;

  HistoryItem({
    required this.lineName,
    required this.timestamp,
    required this.isActive,
  });
}

class RelayStatus {
  final String name;
  final bool isOn;

  RelayStatus({required this.name, required this.isOn});
}
