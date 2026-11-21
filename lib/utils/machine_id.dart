import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:win32_registry/win32_registry.dart';

/// Salted SHA-256 of this device's machine ID, formatted like a UUID.
///
/// Stable across app reinstalls on the same device, different on another
/// device. The raw machine ID never leaves this function, so the result is
/// safe to send to analytics. Returns null when no machine ID is available.
Future<String?> machineIdHash() async {
  try {
    final raw = (await _rawMachineId())?.trim() ?? '';
    if (raw.isEmpty) return null;
    final hex = sha256.convert(utf8.encode('$raw:invoiso')).toString();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  } catch (_) {
    return null;
  }
}

Future<String?> _rawMachineId() async {
  final info = DeviceInfoPlugin();
  if (Platform.isWindows) {
    final id = (await info.windowsInfo).deviceId;
    if (id.trim().isNotEmpty) return id;
    // SQMClient MachineId is missing on some setups (telemetry off, LTSC).
    final key = Registry.openPath(RegistryHive.localMachine,
        path: r'SOFTWARE\Microsoft\Cryptography');
    try {
      return key.getStringValue('MachineGuid');
    } finally {
      key.close();
    }
  }
  if (Platform.isLinux) return (await info.linuxInfo).machineId;
  if (Platform.isMacOS) return (await info.macOsInfo).systemGUID;
  if (Platform.isAndroid) return const AndroidId().getId();
  if (Platform.isIOS) return (await info.iosInfo).identifierForVendor;
  return null;
}
