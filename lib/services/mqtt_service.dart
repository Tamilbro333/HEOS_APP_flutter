// ==========================================
// FILE: lib/services/mqtt_service.dart
// ==========================================
import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/energy_data.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  late MqttServerClient client;
  final StreamController<EnergyData> _dataController =
      StreamController<EnergyData>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<EnergyData> get dataStream => _dataController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // HiveMQ Cloud Configuration
  final String broker = 'a7e03296a15a4316b325766530a7b8b9.s1.eu.hivemq.cloud';
  final int port = 8883;
  final String username = 'thasnima_mqtt';
  final String password = 'Thasnima@2005';

  // MQTT Topics - MUST MATCH YOUR ESP32 MASTER CODE
  final String liveDataTopic = 'heos/master/livedata';  // Data from ESP32 Master
  final String statusTopic = 'heos/master/status';      // Relay status from ESP32 Master

  Future<void> connect() async {
    client = MqttServerClient.withPort(
      broker,
      'flutter_heos_client_${DateTime.now().millisecondsSinceEpoch}',
      port,
    );
    
    client.logging(on: true); // Enable logging for debugging
    client.keepAlivePeriod = 60;
    client.autoReconnect = true;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;

    // Configure security for HiveMQ Cloud
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;

    // Set connection message with authentication
    client.connectionMessage = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier(
            'flutter_heos_client_${DateTime.now().millisecondsSinceEpoch}')
        .withWillTopic('will')
        .withWillMessage('disconnected')
        .withWillQos(MqttQos.atLeastOnce)
        .startClean();

    try {
      print('🔌 Connecting to HiveMQ Cloud broker at $broker:$port...');
      await client.connect().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection attempt timed out');
        },
      );

      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Connected to HiveMQ Cloud broker');
        _isConnected = true;
        _connectionController.add(true);
        _subscribeToTopics();
      } else {
        final status = client.connectionStatus;
        throw Exception(
            'Connection failed - status: ${status?.state}, return code: ${status?.returnCode}');
      }
    } catch (e) {
      print('❌ Connection failed: $e');
      _isConnected = false;
      _connectionController.add(false);

      if (client.connectionStatus?.state != MqttConnectionState.disconnected) {
        client.disconnect();
      }

      throw Exception('MQTT Connection failed: $e');
    }
  }

  void _subscribeToTopics() {
    print('📡 Starting topic subscriptions...');

    // Subscribe to Master ESP32 topics
    print('📥 Subscribing to live data topic: $liveDataTopic');
    client.subscribe(liveDataTopic, MqttQos.atLeastOnce);

    print('📥 Subscribing to status topic: $statusTopic');
    client.subscribe(statusTopic, MqttQos.atLeastOnce);

    // Listen for updates
    print('👂 Setting up message listener...');
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMessage = messages[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('📥 Received: ${messages[0].topic} -> $payload');

      if (messages[0].topic == liveDataTopic) {
        _parseAndEmitData(payload);
      } else if (messages[0].topic == statusTopic) {
        print('🔄 Status update: $payload');
        _statusController.add(payload);
      }
    });
  }

  void _parseAndEmitData(String payload) {
    try {
      // Expected format from ESP32 Master: S_V:11.90,S_P:28.50,E_V:215.30,E_C:2.70,E_P:621.00
      print('🔍 Parsing data: $payload');
      
      final data = <String, double>{};
      final parts = payload.split(',');

      for (var part in parts) {
        final keyValue = part.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
          data[key] = value;
          print('  📊 $key = $value');
        }
      }

      // Create EnergyData object
      final energyData = EnergyData(
        solarVoltage: data['S_V'] ?? 0.0,
        solarPower: data['S_P'] ?? 0.0,
        ebVoltage: data['E_V'] ?? 0.0,
        ebCurrent: data['E_C'] ?? 0.0,
        ebPower: data['E_P'] ?? 0.0,
      );

      print('✅ Data parsed successfully: $energyData');
      print('📤 Emitting data to dashboard...');
      _dataController.add(energyData);
      print('✅ Data emitted to stream');
    } catch (e) {
      print('❌ Error parsing data: $e');
      print('   Payload was: $payload');
    }
  }

  void _onConnected() {
    print('✅ MQTT client connected');
    _isConnected = true;
    _connectionController.add(true);

    print('📊 Connection Details:');
    print('  - Client ID: ${client.clientIdentifier}');
    print('  - Server: ${client.server}:${client.port}');
    print('  - State: ${client.connectionStatus?.state}');
  }

  void _onDisconnected() {
    print('❌ MQTT client disconnected');
    _isConnected = false;
    _connectionController.add(false);

    print('⚠️ Disconnection Details:');
    print('  - State: ${client.connectionStatus?.state}');
    print('  - Return Code: ${client.connectionStatus?.returnCode}');
  }

  void _onSubscribed(String topic) {
    print('✅ Successfully subscribed to: $topic');
  }

  void _pong() {
    print('🏓 Ping response received - connection alive');
  }

  void disconnect() {
    print('🔌 Disconnecting MQTT client...');
    client.disconnect();
    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    print('🗑️ Disposing MQTT service...');
    _dataController.close();
    _statusController.close();
    _connectionController.close();
    disconnect();
  }
}