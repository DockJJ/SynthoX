import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// ───────────────────────────────────────────────────────────────────────
  /// HOST CONFIGURATION
  /// ───────────────────────────────────────────────────────────────────────
  /// When running on a **physical phone** (USB or wireless debugging),
  /// the phone cannot reach "localhost" or "10.0.2.2" — those only work
  /// inside the Android Emulator. Instead you must use the IP address of
  /// the PC that is running the backend server.
  ///
  /// ➤  Find your PC's IP:  Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
  ///    and look for the IPv4 address on the same Wi-Fi network as your phone.
  ///
  /// ➤  Make sure your phone and PC are on the SAME Wi-Fi network.
  ///
  /// Change the value below to your PC's current Wi-Fi IPv4 address:
  /// ───────────────────────────────────────────────────────────────────────
  static const String _physicalDeviceHost = '192.168.1.108';

  /// Automatically picks the right host for each environment.
  static String get host {
    if (kIsWeb) return 'localhost';

    // On mobile / desktop native
    if (Platform.isAndroid) {
      // If you are using ADB reverse (adb reverse tcp:5000 tcp:5000),
      // you can change this to 'localhost'.
      // For Android Emulator, '10.0.2.2' maps to the host machine.
      // For physical devices, use the Wi-Fi IP.
      return _physicalDeviceHost;
    }

    if (Platform.isIOS) {
      // iOS simulator uses localhost; physical iPhone uses Wi-Fi IP.
      return _physicalDeviceHost;
    }

    // Desktop (Windows / macOS / Linux) — runs on the same machine as the server.
    return 'localhost';
  }

  static int port = 5000;

  static String get baseUrl => 'http://$host:$port/api';
  static String get socketUrl => 'http://$host:$port';
}
