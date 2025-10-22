import 'package:flutter/material.dart';
import 'services/mqtt_service.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatefulWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  final MqttService _mqtt = MqttService();
  String _status = 'Not Connected';
  String _lastData = 'No data yet';

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    await _mqtt.connect();
    
    _mqtt.connectionStream.listen((connected) {
      setState(() {
        _status = connected ? 'Connected ✅' : 'Disconnected ❌';
      });
    });

    _mqtt.dataStream.listen((data) {
      setState(() {
        _lastData = data.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('MQTT Test')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $_status', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Text('Last Data:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_lastData),
            ],
          ),
        ),
      ),
    );
  }
}