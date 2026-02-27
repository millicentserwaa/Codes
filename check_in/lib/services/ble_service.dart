import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/measurement.dart';
import 'hive_service.dart';

class BleService {
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String readCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String controlCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a9";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _readChar;
  BluetoothCharacteristic? _controlChar;

  final HiveService _hiveService = HiveService();

  // Stream controllers
  final _connectionController = StreamController<bool>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _measurementController = StreamController<Measurement>.broadcast();
  final _syncProgressController = StreamController<int>.broadcast();

  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<Measurement> get measurementStream => _measurementController.stream;
  Stream<int> get syncProgressStream => _syncProgressController.stream;

  bool get isConnected => _connectedDevice != null;

  // ── Scan for AF_Monitor ──────────────────────────────────
  Stream<List<ScanResult>> scanForDevice() {
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withNames: ['AF_Monitor'],
    );
    return FlutterBluePlus.scanResults;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // ── Connect to device ────────────────────────────────────
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _statusController.add('Connecting...');
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _readChar = null;
          _controlChar = null;
          _connectionController.add(false);
          _statusController.add('Disconnected');
        }
      });

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid) {
          for (var char in service.characteristics) {
            String uuid = char.uuid.toString().toLowerCase();
            if (uuid == readCharUuid)    _readChar    = char;
            if (uuid == controlCharUuid) _controlChar = char;
          }
        }
      }

      if (_readChar == null || _controlChar == null) {
        _statusController.add('Characteristics not found');
        return false;
      }

      // Enable notifications
      await _readChar!.setNotifyValue(true);
      _connectionController.add(true);
      _statusController.add('Connected to AF_Monitor');
      return true;

    } catch (e) {
      _statusController.add('Connection failed: $e');
      return false;
    }
  }

  // ── Fetch all readings from ESP32 ────────────────────────
  Future<int> syncData() async {
    if (_controlChar == null || _readChar == null) {
      _statusController.add('Not connected');
      return 0;
    }

    final List<Measurement> received = [];
    final completer = Completer<int>();

    final sub = _readChar!.onValueReceived.listen((bytes) async {
      final String raw = utf8.decode(bytes).trim();

      if (raw == 'END') {
        if (!completer.isCompleted) completer.complete(received.length);
        return;
      }

      if (raw == 'CLEARED' || raw.startsWith('COUNT:')) return;

      // Parse CSV: "timestamp,mean_hr,af_prediction,confidence"
      final parts = raw.split(',');
      if (parts.length == 4) {
        try {
          final measurement = Measurement.fromBLE(raw);
          await _hiveService.saveMeasurement(measurement);
          received.add(measurement);
          _measurementController.add(measurement);
          _syncProgressController.add(received.length);
        } catch (e) {
          _statusController.add('Parse error: $e');
        }
      }
    });

    // Send GET_DATA command
    try {
      await _controlChar!.write(
        utf8.encode('GET_DATA'),
        withoutResponse: false,
      );
      _statusController.add('Syncing data...');
    } catch (e) {
      _statusController.add('Command failed: $e');
      sub.cancel();
      return 0;
    }

    // Wait for END signal, max 30 seconds
    try {
      final count = await completer.future.timeout(
        const Duration(seconds: 30),
      );
      sub.cancel();
      _statusController.add('Synced $count measurements');
      return count;
    } catch (_) {
      sub.cancel();
      _statusController.add('Sync timeout — got ${received.length} readings');
      return received.length;
    }
  }

  // Get count from ESP32
  Future<int> getDeviceCount() async {
    if (_controlChar == null || _readChar == null) return 0;

    final completer = Completer<int>();

    final sub = _readChar!.onValueReceived.listen((bytes) {
      final raw = utf8.decode(bytes).trim();
      if (raw.startsWith('COUNT:')) {
        final count = int.tryParse(raw.replaceFirst('COUNT:', '')) ?? 0;
        if (!completer.isCompleted) completer.complete(count);
      }
    });

    await _controlChar!.write(
      utf8.encode('GET_COUNT'),
      withoutResponse: false,
    );

    try {
      final count = await completer.future.timeout(
        const Duration(seconds: 5),
      );
      sub.cancel();
      return count;
    } catch (_) {
      sub.cancel();
      return 0;
    }
  }

  // Clear ESP32 storage
  Future<void> clearDeviceData() async {
    if (_controlChar == null) return;
    await _controlChar!.write(
      utf8.encode('CLEAR_DATA'),
      withoutResponse: false,
    );
    _statusController.add('Device storage cleared');
  }

  // Disconnect 
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _readChar = null;
    _controlChar = null;
    _connectionController.add(false);
    _statusController.add('Disconnected');
  }

  void dispose() {
    _connectionController.close();
    _statusController.close();
    _measurementController.close();
    _syncProgressController.close();
  }
}