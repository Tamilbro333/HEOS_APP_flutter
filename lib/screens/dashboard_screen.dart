// ==========================================
// FILE: lib/screens/dashboard_screen.dart
// ==========================================
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/mqtt_service.dart';
import '../models/energy_data.dart';
import '../widgets/power_line_card.dart';
import '../widgets/total_units_chart.dart';
import '../widgets/relay_status_card.dart';
import '../widgets/history_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MqttService _mqttService = MqttService();

  List<PowerLineData> powerLines = [
    PowerLineData(
      name: 'EB Line',
      currentUsage: 0.0,
      voltageUsage: 0.0,
      power: 0.0,
      usedPercentage: 0.0,
      isActive: false,
    ),
    PowerLineData(
      name: 'Solar Line',
      currentUsage: 0.0,
      voltageUsage: 0.0,
      power: 0.0,
      usedPercentage: 0.0,
      isActive: false,
    ),
  ];

  List<RelayStatus> relayStatuses = [
    RelayStatus(name: 'EB', isOn: false),
    RelayStatus(name: 'Solar', isOn: false),
  ];

  List<HistoryItem> history = [];
  bool _isConnected = false;
  String _currentStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initializeMqtt();
  }

  Future<void> _initializeMqtt() async {
    try {
      // Connect to HiveMQ Cloud (secured TLS)
      await _mqttService.connect();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Connection failed: ${e.toString()}', const Color.fromARGB(255, 255, 255, 255));
        setState(() {
          _isConnected = false;
          _currentStatus = 'Connected';
        });
      }
      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), _initializeMqtt);
      return;
    }

    // Listen to connection status
    _mqttService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        _currentStatus = connected ? 'Connected' : 'Disconnected';
      });

      if (!connected) {
        _showSnackBar('MQTT Disconnected. Reconnecting...', Colors.red);
        Future.delayed(const Duration(seconds: 3), () {
          if (!_mqttService.isConnected) {
            _mqttService.connect();
          }
        });
      } else {
        _showSnackBar('MQTT Connected Successfully!', Colors.green);
      }
    });

    // Listen to energy data
    _mqttService.dataStream.listen((data) {
      print('📊 Dashboard received data update: $data');
      setState(() {
        _updateDashboard(data);
      });
      print('🔄 Dashboard UI updated');
    });

    // Listen to status updates
    _mqttService.statusStream.listen((status) {
      _updateRelayStatus(status);
      _addHistory(status);
    });
  }

  void _updateDashboard(EnergyData data) {
    setState(() {
      // Update EB Line
      powerLines[0] = PowerLineData(
        name: 'EB Line',
        currentUsage: data.ebCurrent,
        voltageUsage: data.ebVoltage,
        power: data.ebPower,
        usedPercentage: _calculateUsagePercentage(data.ebPower, 3000),
        isActive: relayStatuses[0].isOn,
      );

      // Update Solar Line
      powerLines[1] = PowerLineData(
        name: 'Solar Line',
        currentUsage: data.solarCurrent,
        voltageUsage: data.solarVoltage,
        power: data.solarPower,
        usedPercentage: _calculateUsagePercentage(data.solarPower, 100),
        isActive: relayStatuses[1].isOn,
      );
    });
  }

  double _calculateUsagePercentage(double power, double maxPower) {
    return ((power / maxPower) * 100).clamp(0, 100);
  }

  void _updateRelayStatus(String status) {
    setState(() {
      if (status == 'SOLAR') {
        relayStatuses[0] = RelayStatus(name: 'EB', isOn: false);
        relayStatuses[1] = RelayStatus(name: 'Solar', isOn: true);
        powerLines[0] = PowerLineData(
          name: powerLines[0].name,
          currentUsage: powerLines[0].currentUsage,
          voltageUsage: powerLines[0].voltageUsage,
          power: powerLines[0].power,
          usedPercentage: powerLines[0].usedPercentage,
          isActive: false,
        );
        powerLines[1] = PowerLineData(
          name: powerLines[1].name,
          currentUsage: powerLines[1].currentUsage,
          voltageUsage: powerLines[1].voltageUsage,
          power: powerLines[1].power,
          usedPercentage: powerLines[1].usedPercentage,
          isActive: true,
        );
      } else if (status == 'EB') {
        relayStatuses[0] = RelayStatus(name: 'EB', isOn: true);
        relayStatuses[1] = RelayStatus(name: 'Solar', isOn: false);
        powerLines[0] = PowerLineData(
          name: powerLines[0].name,
          currentUsage: powerLines[0].currentUsage,
          voltageUsage: powerLines[0].voltageUsage,
          power: powerLines[0].power,
          usedPercentage: powerLines[0].usedPercentage,
          isActive: true,
        );
        powerLines[1] = PowerLineData(
          name: powerLines[1].name,
          currentUsage: powerLines[1].currentUsage,
          voltageUsage: powerLines[1].voltageUsage,
          power: powerLines[1].power,
          usedPercentage: powerLines[1].usedPercentage,
          isActive: false,
        );
      }
    });
  }

  void _addHistory(String status) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newItem = HistoryItem(
      lineName: status == 'SOLAR' ? 'Solar Line' : 'EB Line',
      timestamp: timestamp,
      isActive: true,
    );

    setState(() {
      // Mark previous items as inactive
      history = history
          .map((item) => HistoryItem(
                lineName: item.lineName,
                timestamp: item.timestamp,
                isActive: false,
              ))
          .toList();

      // Add new item at the beginning
      history.insert(0, newItem);

      // Keep only last 10 items
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshData() async {
    if (!_mqttService.isConnected) {
      await _mqttService.connect();
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HEOS Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.white : Colors.red[200],
                ),
                const SizedBox(width: 8),
                Text(
                  _currentStatus,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Power Line Cards
              ...powerLines.map((line) => PowerLineCard(data: line)),
              const SizedBox(height: 20),

              // Total Units Chart
              TotalUnitsChart(powerLines: powerLines),
              const SizedBox(height: 20),

              // Relay Status
              RelayStatusCard(relayStatuses: relayStatuses),
              const SizedBox(height: 20),

              // History
              HistoryCard(history: history),
            ],
          ),
        ),
      ),
    );
  }
}
