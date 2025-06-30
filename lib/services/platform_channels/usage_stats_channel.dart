import 'package:flutter/services.dart';
import 'dart:developer' as developer; // For logging

class UsageStatsChannel {
  static const _platform = MethodChannel('com.tasktime.app/usage_stats');
  static const String _tag = 'UsageStatsChannel';

  // Method to request permission from the native side
  // Returns true if the intent to open settings was successfully sent, false otherwise
  // Note: This doesn't confirm if permission was granted, only that the settings page was opened.
  static Future<bool> requestPermission() async {
    try {
      developer.log('Requesting Usage Stats permission via platform channel', name: _tag);
      final bool? result = await _platform.invokeMethod('requestUsageStatsPermission');
      developer.log('Platform channel requestUsageStatsPermission result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to request Usage Stats permission: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  // Method to check if permission is granted (more complex for Usage Stats)
  // This might also be a native method that returns a boolean
  static Future<bool> hasPermission() async {
    try {
      developer.log('Checking Usage Stats permission via platform channel', name: _tag);
      final bool? result = await _platform.invokeMethod('hasUsageStatsPermission');
      developer.log('Platform channel hasUsageStatsPermission result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to check Usage Stats permission: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  // Method to fetch usage stats
  // intervalType: "daily", "weekly", "monthly" (or custom if supported by native)
  // startTime, endTime: for custom ranges (optional)
  static Future<Map<String, Duration>> getAppUsageDurations({
    String intervalType = "daily",
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final Map<String, dynamic>? rawStats = await _platform.invokeMethod(
        'getUsageStats',
        {
          'intervalType': intervalType,
          'startTime': startTime?.millisecondsSinceEpoch,
          'endTime': endTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (rawStats == null) {
        developer.log('Received null stats from platform channel', name: _tag);
        return {};
      }

      final Map<String, Duration> usageDurations = {};
      rawStats.forEach((packageName, timeInMillis) {
        if (timeInMillis is int) { // Native side sends Long, which is int in Dart
          usageDurations[packageName] = Duration(milliseconds: timeInMillis);
        } else if (timeInMillis is double) { // Just in case
           usageDurations[packageName] = Duration(milliseconds: timeInMillis.toInt());
        }
      });
      developer.log('Successfully fetched and parsed ${usageDurations.length} usage stats entries.', name: _tag);
      return usageDurations;
    } on PlatformException catch (e) {
      developer.log('Failed to get usage stats: ${e.message}', name: _tag, error: e);
      return {};
    } catch (e, s) {
      developer.log('Error processing usage stats: $e', name: _tag, error: e, stackTrace: s);
      return {};
    }
  }
}
