import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Must match firmware definitions exactly
const String _serviceUUID        = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String _dataCharUUID       = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String _countCharUUID      = 'beb5483f-36e1-4688-b7f5-ea07361b26a8';
const String _commandCharUUID    = 'beb54840-36e1-4688-b7f5-ea07361b26a8';
const String _liveEcgCharUUID    = 'beb54841-36e1-4688-b7f5-ea07361b26a8';

const String deviceName = 'AF-SCREEN';

enum BleStatus { off, scanning, found, connecting, connected, disconnected, error }

class DeviceReading {
  final double cv;
  final double rmssd;
  final double pnn50;
  final double meanRR;
  final double heartRate;
  final int afResultIndex;
  final int afScore;
  final int systolicBP;
  final DateTime timestamp;

  DeviceReading({
    required this.cv,
    required this.rmssd,
    required this.pnn50,
    required this.meanRR,
    required this.heartRate,
    required this.afResultIndex,
    required this.afScore,
    required this.systolicBP,
    required this.timestamp,
  });

  factory DeviceReading.fromJson(Map<String, dynamic> json) {
    return DeviceReading(
      cv:            (json['cv'] as num).toDouble(),
      rmssd:         (json['rmssd'] as num).toDouble(),
      pnn50:         (json['pnn50'] as num).toDouble(),
      meanRR:        (json['mean_rr'] as num).toDouble(),
      heartRate:     (json['hr'] as num).toDouble(),
      afResultIndex: json['af_result'] as int,
      afScore:       json['af_score'] as int,
      systolicBP:    (json['sbp'] ?? 0) as int,
      timestamp:     DateTime.fromMillisecondsSinceEpoch(
                       (json['ts'] as int) * 1000),
    );
  }
}

class BleService extends ChangeNotifier {
  BleStatus _status = BleStatus.disconnected;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _dataChar;
  BluetoothCharacteristic? _countChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _liveEcgChar;

  String _statusMessage = 'Not connected';
  final int _batteryPercent = -1;
  List<double> _liveEcgBuffer = [];

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _liveEcgSubscription;

  // Stream for live ECG samples
  final _ecgController = StreamController<List<double>>.broadcast();
  Stream<List<double>> get ecgStream => _ecgController.stream;

  // Stream for completed measurements
  final _readingController = StreamController<DeviceReading>.broadcast();
  Stream<DeviceReading> get readingStream => _readingController.stream;

  BleStatus get status => _status;
  String get statusMessage => _statusMessage;
  bool get isConnected => _status == BleStatus.connected;
  int get batteryPercent => _batteryPercent;
  BluetoothDevice? get device => _device;

  // ── Scan ──────────────────────────────────────────────────
  Future<void> startScan() async {
    _setStatus(BleStatus.scanning, 'Scanning for AF-Screen device...');

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withNames: [deviceName],
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.platformName == deviceName) {
          _setStatus(BleStatus.found, 'Device found! Connecting...');
          stopScan();
          connect(r.device);
          return;
        }
      }
    });

    // Timeout handler
    Future.delayed(const Duration(seconds: 16), () {
      if (_status == BleStatus.scanning) {
        _setStatus(BleStatus.disconnected, 'No device found. Make sure AF-Screen is powered on.');
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  // ── Connect ───────────────────────────────────────────────
  Future<void> connect(BluetoothDevice device) async {
    try {
      _setStatus(BleStatus.connecting, 'Connecting...');
      _device = device;

      await device.connect(timeout: const Duration(seconds: 10));
      _setStatus(BleStatus.connected, 'Connected to ${device.platformName}');

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      await _discoverServices();
    } catch (e) {
      _setStatus(BleStatus.error, 'Connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    _dataChar = null;
    _countChar = null;
    _commandChar = null;
    _liveEcgChar = null;
    _notifySubscription?.cancel();
    _liveEcgSubscription?.cancel();
    _setStatus(BleStatus.disconnected, 'Disconnected from device.');
  }

  // ── Discover services & characteristics ───────────────────
  Future<void> _discoverServices() async {
    if (_device == null) return;

    final services = await _device!.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == _serviceUUID.toLowerCase()) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == _dataCharUUID.toLowerCase())    _dataChar = char;
          if (uuid == _countCharUUID.toLowerCase())   _countChar = char;
          if (uuid == _commandCharUUID.toLowerCase()) _commandChar = char;
          if (uuid == _liveEcgCharUUID.toLowerCase()) _liveEcgChar = char;
        }
        break;
      }
    }

    // Subscribe to data notifications (completed measurements)
    if (_dataChar != null && _dataChar!.properties.notify) {
      await _dataChar!.setNotifyValue(true);
      _notifySubscription = _dataChar!.onValueReceived.listen(_onDataReceived);
    }

    // Subscribe to live ECG stream
    if (_liveEcgChar != null && _liveEcgChar!.properties.notify) {
      await _liveEcgChar!.setNotifyValue(true);
      _liveEcgSubscription = _liveEcgChar!.onValueReceived.listen(_onLiveEcg);
    }
  }

  // ── Receive completed measurement ─────────────────────────
  void _onDataReceived(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final reading = DeviceReading.fromJson(json);
      _readingController.add(reading);
    } catch (e) {
      debugPrint('BLE data parse error: $e');
    }
  }

  // ── Receive live ECG samples ──────────────────────────────
  void _onLiveEcg(List<int> bytes) {
    // Device sends 2 bytes per sample (big-endian uint16)
    final samples = <double>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final raw = (bytes[i] << 8) | bytes[i + 1];
      // Convert ADC value (0–4095) to voltage-like float 0–3.3
      samples.add(raw * 3.3 / 4095.0);
    }
    _liveEcgBuffer.addAll(samples);
    if (_liveEcgBuffer.length > 1080) { // Keep 3 seconds at 360 Hz
      _liveEcgBuffer = _liveEcgBuffer.sublist(_liveEcgBuffer.length - 1080);
    }
    _ecgController.add(List.from(_liveEcgBuffer));
  }

  // ── Commands to device ────────────────────────────────────
  Future<int> getRecordCount() async {
    if (_countChar == null) return 0;
    final val = await _countChar!.read();
    return val.isNotEmpty ? val[0] : 0;
  }

  Future<void> requestData() async {
    if (_commandChar == null) return;
    await _commandChar!.write(utf8.encode('GET_DATA'));
  }

  Future<void> clearData() async {
    if (_commandChar == null) return;
    await _commandChar!.write([0xAA]); // Confirmation byte from firmware
  }

  // ── Helpers ───────────────────────────────────────────────
  void _setStatus(BleStatus s, String msg) {
    _status = s;
    _statusMessage = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    stopScan();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _liveEcgSubscription?.cancel();
    _ecgController.close();
    _readingController.close();
    super.dispose();
  }
}
