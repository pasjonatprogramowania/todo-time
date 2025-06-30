import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class BackgroundServiceChannel {
  static const _platform = MethodChannel('com.tasktime.app/background_service');
  static const String _tag = 'BackgroundServiceChannel';

  static Future<String?> startService() async {
    try {
      developer.log('Requesting to start background service', name: _tag);
      final String? result = await _platform.invokeMethod('startService');
      developer.log('Start service platform channel result: $result', name: _tag);
      return result;
    } on PlatformException catch (e) {
      developer.log('Failed to start background service: ${e.message}', name: _tag, error: e);
      return "Failed: ${e.message}";
    }
  }

  static Future<String?> updateConfiguration({
    required List<Map<String, dynamic>> schedule, // Serialized BlockScheduleEntry
    required List<String> blockedAppPackages,
    required List<String> blockedWebsiteHosts,
  }) async {
    try {
      developer.log('Sending configuration to background service', name: _tag);
      final String? result = await _platform.invokeMethod('updateConfiguration', {
        'schedule': schedule,
        'blockedAppPackages': blockedAppPackages,
        'blockedWebsiteHosts': blockedWebsiteHosts,
      });
      developer.log('Update configuration platform channel result: $result', name: _tag);
      return result;
    } on PlatformException catch (e) {
      developer.log('Failed to update service configuration: ${e.message}', name: _tag, error: e);
      return "Failed: ${e.message}";
    }
  }

  static Future<String?> stopService() async {
    try {
      developer.log('Requesting to stop background service', name: _tag);
      final String? result = await _platform.invokeMethod('stopService');
      developer.log('Stop service platform channel result: $result', name: _tag);
      return result;
    } on PlatformException catch (e) {
      developer.log('Failed to stop background service: ${e.message}', name: _tag, error: e);
      return "Failed: ${e.message}";
    }
  }

  // Example for a method that might get service status in the future
  // static Future<Map<String, dynamic>?> getServiceStatus() async {
  //   try {
  //     final Map<dynamic, dynamic>? result = await _platform.invokeMethod('getServiceStatus');
  //     return result?.cast<String, dynamic>();
  //   } on PlatformException catch (e) {
  //     developer.log('Failed to get service status: ${e.message}', name: _tag, error: e);
  //     return null;
  //   }
  // }
}
