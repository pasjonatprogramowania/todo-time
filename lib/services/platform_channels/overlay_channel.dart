import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class OverlayChannel {
  static const _platform = MethodChannel('com.tasktime.app/overlay');
  static const String _tag = 'OverlayChannel';

  static Future<bool> requestPermission() async {
    try {
      developer.log('Requesting Display Over Other Apps permission', name: _tag);
      final bool? result = await _platform.invokeMethod('requestOverlayPermission');
      developer.log('Platform channel requestOverlayPermission result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to request Overlay permission: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      developer.log('Checking Display Over Other Apps permission', name: _tag);
      final bool? result = await _platform.invokeMethod('hasOverlayPermission');
      developer.log('Platform channel hasOverlayPermission result: $result', name: _tag);
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log('Failed to check Overlay permission: ${e.message}', name: _tag, error: e);
      return false;
    }
  }

  // Placeholder for showing/hiding overlay - Step 6
  static Future<void> showOverlay() async {
    try {
      developer.log('Requesting to show overlay', name: _tag);
      await _platform.invokeMethod('showOverlay');
    } on PlatformException catch (e) {
      developer.log('Failed to show overlay: ${e.message}', name: _tag, error: e);
    }
  }

  static Future<void> hideOverlay() async {
    try {
      developer.log('Requesting to hide overlay', name: _tag);
      await _platform.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      developer.log('Failed to hide overlay: ${e.message}', name: _tag, error: e);
    }
  }
}
