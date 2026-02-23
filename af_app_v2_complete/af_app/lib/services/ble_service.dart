import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String _serviceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String _dataCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String _countCharUUID = 'beb5483f-36e1-4688-b7f5-ea07361b26a8';
const String _commandCharUUID = 'beb54840-36e1-4688-b7f5-ea07361b26a8';
const String _liveEcgCharUUID = 'beb54841-36e1-4688-b7f5-ea07361b26a8';

// ← match EXACTLY what your firmware advertises in BLEDevice.setDeviceName()
const String deviceName = 'AF_Monitor';

enum BleStatus {
  off,
  scanning,
  found,
  connecting,
  connected,
  disconnected,
  error
}

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
      cv: (json['cv'] as num).toDouble(),
      rmssd: (json['rmssd'] as num).toDouble(),
      pnn50: (json['pnn50'] as num).toDouble(),
      meanRR: (json['mean_rr'] as num).toDouble(),
      heartRate: (json['hr'] as num).toDouble(),
      afResultIndex: json['af_result'] as int,
      afScore: json['af_score'] as int,
      systolicBP: (json['sbp'] ?? 0) as int,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch((json['ts'] as int) * 1000),
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
  List<double> _liveEcgBuffer = [];

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _liveEcgSubscription;

  final _ecgController = StreamController<List<double>>.broadcast();
  final _readingController = StreamController<DeviceReading>.broadcast();

  Stream<List<double>> get ecgStream => _ecgController.stream;
  Stream<DeviceReading> get readingStream => _readingController.stream;

  BleStatus get status => _status;
  String get statusMessage => _statusMessage;
  bool get isConnected => _status == BleStatus.connected;
  BluetoothDevice? get device => _device;

  // last scan results (unique by id)
  final Map<DeviceIdentifier, ScanResult> _scanResults = {};
  List<ScanResult> get scanResults => _scanResults.values.toList();

  // ── Permissions ───────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;

    // Android 12+ needs bluetoothScan + bluetoothConnect
    // Android <12 needs location for BLE scanning
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // required for BLE scan on all Android
    ].request();

    final allGranted =
        results.values.every((s) => s == PermissionStatus.granted);

    if (!allGranted) {
      final denied = results.entries
          .where((e) => e.value != PermissionStatus.granted)
          .map((e) => e.key.toString())
          .join(', ');
      debugPrint('❌ Permissions denied: $denied');
      _setStatus(BleStatus.error,
          'Permissions denied. Please grant Bluetooth and Location in Settings.');
      return false;
    }
    debugPrint('✅ All BLE permissions granted');
    return true;
  }

  // ── Scan ──────────────────────────────────────────────────
  Future<void> startScan() async {
    final ok = await _requestPermissions();
    if (!ok) return;

    // Check adapter is on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _setStatus(BleStatus.off,
          'Bluetooth is off. Please turn on Bluetooth and try again.');
      return;
    }

    _scanResults.clear();
    _setStatus(BleStatus.scanning, 'Scanning for AF device...');
    debugPrint('🔵 Scan started — discovering all devices');

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );

    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        // collect ALL devices into the map
        _scanResults[r.device.remoteId] = r;
        notifyListeners(); // update UI with new list

        // Use platformName OR localName from advertisement
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : r.advertisementData.localName;

        debugPrint('🔵 Found: "$name" (${r.device.remoteId})');
      }
    });

    // Timeout
    Future.delayed(const Duration(seconds: 16), () {
      if (_status == BleStatus.scanning) {
        debugPrint('❌ Scan timed out');
        stopScan();
        _setStatus(BleStatus.disconnected,
            'Device not found. Make sure the AF device is powered on and nearby.');
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  // ── Connect ───────────────────────────────────────────────
  Future<void> connect(BluetoothDevice device) async {
    try {
      _setStatus(BleStatus.connecting, 'Connecting to device...');
      _device = device;

      await device.connect(
          timeout: const Duration(seconds: 10), license: License.free);
      _setStatus(BleStatus.connected, 'Connected to ${device.platformName}');
      debugPrint('✅ Connected to ${device.platformName}');

      _connectionSubscription = device.connectionState.listen((state) {
        debugPrint('🔵 Connection state: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      await _discoverServices();
    } catch (e) {
      debugPrint('❌ Connection error: $e');
      _setStatus(BleStatus.error, 'Connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    _dataChar = _countChar = _commandChar = _liveEcgChar = null;
    _notifySubscription?.cancel();
    _liveEcgSubscription?.cancel();
    _device = null;
    _setStatus(BleStatus.disconnected, 'Disconnected from device.');
    debugPrint('🔵 Device disconnected');
  }

  // ── Discover services ─────────────────────────────────────
  Future<void> _discoverServices() async {
    if (_device == null) return;
    debugPrint('🔵 Discovering services...');

    final services = await _device!.discoverServices();
    debugPrint('🔵 Found ${services.length} services');

    for (final service in services) {
      debugPrint('🔵 Service: ${service.uuid}');
      if (service.uuid.toString().toLowerCase() == _serviceUUID.toLowerCase()) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          debugPrint('  🔵 Characteristic: $uuid');
          if (uuid == _dataCharUUID.toLowerCase()) _dataChar = char;
          if (uuid == _countCharUUID.toLowerCase()) _countChar = char;
          if (uuid == _commandCharUUID.toLowerCase()) _commandChar = char;
          if (uuid == _liveEcgCharUUID.toLowerCase()) _liveEcgChar = char;
        }
        break;
      }
    }

    if (_dataChar == null) {
      debugPrint('⚠️ Data characteristic not found — check UUIDs in firmware');
    }

    if (_dataChar != null && _dataChar!.properties.notify) {
      await _dataChar!.setNotifyValue(true);
      _notifySubscription = _dataChar!.onValueReceived.listen(_onDataReceived);
      debugPrint('✅ Subscribed to data notifications');
    }

    if (_liveEcgChar != null && _liveEcgChar!.properties.notify) {
      await _liveEcgChar!.setNotifyValue(true);
      _liveEcgSubscription = _liveEcgChar!.onValueReceived.listen(_onLiveEcg);
      debugPrint('✅ Subscribed to live ECG stream');
    }
  }

  // ── Receive data ──────────────────────────────────────────
  void _onDataReceived(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final reading = DeviceReading.fromJson(json);
      debugPrint(
          '✅ Measurement received: HR=${reading.heartRate} CV=${reading.cv}');
      _readingController.add(reading);
    } catch (e) {
      debugPrint('❌ BLE data parse error: $e');
    }
  }

  void _onLiveEcg(List<int> bytes) {
    final samples = <double>[];
    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final raw = (bytes[i] << 8) | bytes[i + 1];
      samples.add(raw * 3.3 / 4095.0);
    }
    _liveEcgBuffer.addAll(samples);
    if (_liveEcgBuffer.length > 1080) {
      _liveEcgBuffer = _liveEcgBuffer.sublist(_liveEcgBuffer.length - 1080);
    }
    _ecgController.add(List.from(_liveEcgBuffer));
  }

  // ── Commands ──────────────────────────────────────────────
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
    await _commandChar!.write([0xAA]);
  }

  void _setStatus(BleStatus s, String msg) {
    _status = s;
    _statusMessage = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    stopScan();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _liveEcgSubscription?.cancel();
    _ecgController.close();
    _readingController.close();
    super.dispose();
  }
}
