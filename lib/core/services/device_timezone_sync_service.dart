import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../di/providers.dart';

/// Keeps the backend's timezone for the signed-in user aligned with the
/// timezone currently reported by their device.
class DeviceTimezoneSyncService {
  DeviceTimezoneSyncService({required ApiService apiService})
    : _apiService = apiService;

  final ApiService _apiService;
  Future<void>? _inFlight;

  /// Best-effort by design: a platform or network failure must not affect the
  /// user's ability to open the app.
  Future<void> sync() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _sync();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<void> _sync() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      await _apiService.updateDeviceTimezone(timezone.identifier);
    } catch (error) {
      debugPrint('Device timezone sync failed: $error');
    }
  }
}
