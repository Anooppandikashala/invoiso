import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Barcode scanning service supporting multiple input methods:
/// 1. Keyboard wedge (USB/Bluetooth IR scanners)
/// 2. Camera-based scanning
/// 3. Serial/HID devices
class BarcodeScannerService {
  static final BarcodeScannerService _instance = BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  // Keyboard wedge support
  final _keyboardScanController = StreamController<String>.broadcast();
  Stream<String> get keyboardScans => _keyboardScanController.stream;

  String _keyboardBuffer = '';
  DateTime? _lastKeyPress;
  static const _scanTimeout = Duration(milliseconds: 100);
  Timer? _keyboardDebounce;

  // Camera scanner controller
  MobileScannerController? _cameraController;

  // Serial port support
  final _serialScanController = StreamController<String>.broadcast();
  Stream<String> get serialScans => _serialScanController.stream;

  /// Initialize keyboard wedge listener
  /// Call this in your widget's initState and pass KeyEvents from RawKeyboardListener
  void handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();

    // Reset buffer if timeout exceeded (new scan starting)
    if (_lastKeyPress != null && now.difference(_lastKeyPress!) > _scanTimeout) {
      _keyboardBuffer = '';
    }
    _lastKeyPress = now;

    // Handle character input
    final char = event.character;
    if (char != null && char.isNotEmpty) {
      // Ignore newline/enter as it signals end of scan
      if (char == '\n' || char == '\r') {
        if (_keyboardBuffer.isNotEmpty) {
          _emitKeyboardScan(_keyboardBuffer.trim());
          _keyboardBuffer = '';
        }
      } else {
        _keyboardBuffer += char;
      }
    }

    // Also handle Enter key explicitly
    if (event.logicalKey == LogicalKeyboardKey.enter && _keyboardBuffer.isNotEmpty) {
      _emitKeyboardScan(_keyboardBuffer.trim());
      _keyboardBuffer = '';
    }

    // Auto-emit after timeout (some scanners don't send Enter)
    _keyboardDebounce?.cancel();
    _keyboardDebounce = Timer(_scanTimeout, () {
      if (_keyboardBuffer.isNotEmpty) {
        _emitKeyboardScan(_keyboardBuffer.trim());
        _keyboardBuffer = '';
      }
    });
  }

  void _emitKeyboardScan(String barcode) {
    if (barcode.length >= 3) { // Minimum barcode length
      _keyboardScanController.add(barcode);
      if (kDebugMode) print('Keyboard scanner: $barcode');
    }
  }

  /// Create camera scanner controller
  MobileScannerController createCameraController({
    DetectionSpeed detectionSpeed = DetectionSpeed.normal,
    CameraFacing facing = CameraFacing.back,
    List<BarcodeFormat> formats = const [
      BarcodeFormat.all,
    ],
  }) {
    _cameraController?.dispose();
    _cameraController = MobileScannerController(
      detectionSpeed: detectionSpeed,
      facing: facing,
      formats: formats,
    );
    return _cameraController!;
  }

  /// Get the current camera controller (if any)
  MobileScannerController? get cameraController => _cameraController;

  /// Initialize serial port scanning
  /// Platform-specific implementation required
  Future<bool> initializeSerialScanner({
    String? portName,
    int baudRate = 9600,
  }) async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      if (kDebugMode) print('Serial scanning not supported on this platform');
      return false;
    }

    try {
      // Serial port implementation would go here
      // This requires platform-specific setup
      if (kDebugMode) print('Serial scanner initialization not yet implemented');
      return false;
    } catch (e) {
      if (kDebugMode) print('Failed to initialize serial scanner: $e');
      return false;
    }
  }

  /// Emit a scan from serial port
  void emitSerialScan(String barcode) {
    if (barcode.isNotEmpty) {
      _serialScanController.add(barcode);
      if (kDebugMode) print('Serial scanner: $barcode');
    }
  }

  /// Dispose all resources
  void dispose() {
    _keyboardDebounce?.cancel();
    _keyboardScanController.close();
    _cameraController?.dispose();
    _cameraController = null;
    _serialScanController.close();
  }
}

/// Scanner type enum
enum ScannerType {
  keyboard,
  camera,
  serial,
}

/// Barcode scan result
class BarcodeScanResult {
  final String barcode;
  final ScannerType type;
  final DateTime timestamp;

  BarcodeScanResult({
    required this.barcode,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'BarcodeScanResult(barcode: $barcode, type: $type, time: $timestamp)';
}
