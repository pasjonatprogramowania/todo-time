import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class AccessibilityChannel {
  static const _methodChannel = MethodChannel('com.tasktime.app/accessibility_methods');
  static const _eventChannel = EventChannel('com.tasktime.app/accessibility_events');
  static const String _tag = 'AccessibilityChannel';

  // Method Channel: Requesting permission / opening settings
  static Future<bool> requestPermission() async {
    try {
      developer.log('Requesting Accessibility Service permission', name: _tag);
      final bool? result = await _methodChannel.invokeMethod('requestAccessibilityPermission');
      developer.log('Platform channel requestAccessibilityPermission result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to request Accessibility permission: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  // Method Channel: Checking if service is enabled
  static Future<bool> isServiceEnabled() async {
    try {
      developer.log('Checking if Accessibility Service is enabled', name: _tag);
      final bool? result = await _methodChannel.invokeMethod('isAccessibilityServiceEnabled');
      developer.log('Platform channel isAccessibilityServiceEnabled result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to check Accessibility Service status: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  // Event Channel: Stream for active app package name (will be fully implemented in Step 5)
  static Stream<String>? _activeAppPackageNameStream;

  static Stream<String> get activeAppPackageNameStream {
    developer.log('Accessing activeAppPackageNameStream', name: _tag);
    _activeAppPackageNameStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
    return _activeAppPackageNameStream!;
  }

  // Example method that might be called from native to Flutter (via MethodChannel on Flutter side)
  // This is not standard for this channel but shows possibility.
  // Usually, native calls Flutter methods using a separate channel or a BackgroundMethodCallDispatcher.
}
