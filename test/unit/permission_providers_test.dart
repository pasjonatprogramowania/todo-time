import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_time/presentation/providers/permission_providers.dart';
import 'package:task_time/services/platform_channels/accessibility_channel.dart';
import 'package:task_time/services/platform_channels/overlay_channel.dart';
import 'package:task_time/services/platform_channels/usage_stats_channel.dart';

// Mocks for the channel classes are not strictly necessary if we test PermissionStatusNotifier directly
// by providing mock checker/requester functions. However, if we wanted to test the providers
// that instantiate these notifiers using the actual channels, we'd need to mock the channels.
// For now, let's focus on testing PermissionStatusNotifier's logic.

// Helper mock functions for checker and requester
class MockPermissionFunctions {
  Future<bool> check() async => false;
  Future<bool> request() async => false; // request usually returns bool indicating if intent was sent
}

class MockPermissionFunctionsSpies extends Mock implements MockPermissionFunctions {}


void main() {
  group('PermissionStatusNotifier', () {
    late MockPermissionFunctionsSpies mockFunctions;

    setUp(() {
      mockFunctions = MockPermissionFunctionsSpies();
    });

    test('initial state is loading, then updates with checker result (granted)', () async {
      when(mockFunctions.check()).thenAnswer((_) async => true);

      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');

      // Initial state should be loading before checkStatus completes
      expect(notifier.debugState, const AsyncValue<bool>.loading());

      // Wait for checkStatus to complete (it's called in constructor)
      await Future.delayed(Duration.zero);
      expect(notifier.debugState, const AsyncValue<bool>.data(true));
      verify(mockFunctions.check()).called(1);
    });

    test('initial state is loading, then updates with checker result (not granted)', () async {
      when(mockFunctions.check()).thenAnswer((_) async => false);

      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');

      expect(notifier.debugState, const AsyncValue<bool>.loading());
      await Future.delayed(Duration.zero);
      expect(notifier.debugState, const AsyncValue<bool>.data(false));
      verify(mockFunctions.check()).called(1);
    });

    test('checkStatus updates state correctly', () async {
      when(mockFunctions.check()).thenAnswer((_) async => false);
      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');
      await Future.delayed(Duration.zero); // Initial check

      when(mockFunctions.check()).thenAnswer((_) async => true); // Subsequent check
      await notifier.checkStatus();
      expect(notifier.debugState, const AsyncValue<bool>.data(true));
      verify(mockFunctions.check()).called(2); // Called once in constructor, once manually
    });

    test('requestPermission calls requester and then re-checks status', () async {
      when(mockFunctions.check()).thenAnswer((_) async => false); // Initially not granted
      when(mockFunctions.request()).thenAnswer((_) async {
         // Simulate permission being granted after request
        when(mockFunctions.check()).thenAnswer((_) async => true);
        return true; // Request attempt was successful
      });

      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');
      await Future.delayed(Duration.zero); // Initial check
      expect(notifier.debugState, const AsyncValue<bool>.data(false));

      await notifier.requestPermission();

      // Verify requester was called
      verify(mockFunctions.request()).called(1);
      // Verify check was called again after request (once initially, once after request)
      // The PermissionStatusNotifier's requestPermission calls checkStatus after a delay.
      await Future.delayed(const Duration(milliseconds: 550)); // Ensure checkStatus after delay has run

      expect(notifier.debugState, const AsyncValue<bool>.data(true));
      verify(mockFunctions.check()).called(2);
    });

    test('handles error during checkStatus', () async {
      final error = Exception('Check failed');
      when(mockFunctions.check()).thenThrow(error);

      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');
      await Future.delayed(Duration.zero);

      expect(notifier.debugState.hasError, isTrue);
      expect(notifier.debugState.error, error);
    });

    test('handles error during requestPermission', () async {
      final error = Exception('Request failed');
      when(mockFunctions.check()).thenAnswer((_) async => false);
      when(mockFunctions.request()).thenThrow(error);

      final notifier = PermissionStatusNotifier(mockFunctions.check, mockFunctions.request, 'TestPermission');
      await Future.delayed(Duration.zero);

      await notifier.requestPermission();
      // The error from request() itself doesn't go into the main state unless checkStatus fails subsequently.
      // The PermissionStatusNotifier catches error from _requester and sets state to error.
      expect(notifier.debugState.hasError, isTrue);
      expect(notifier.debugState.error, isA<String>()); // 'Failed to request permission: $e'
    });

    test('requestPermission when requester is null (manual navigation)', () async {
      when(mockFunctions.check()).thenAnswer((_) async => false); // Initially not granted

      // Create notifier with null requester
      final notifier = PermissionStatusNotifier(mockFunctions.check, null, 'ManualPermission');
      await Future.delayed(Duration.zero); // Initial check
      expect(notifier.debugState, const AsyncValue<bool>.data(false));

      // Simulate user grants permission manually after settings are opened
      when(mockFunctions.check()).thenAnswer((_) async => true);

      await notifier.requestPermission(); // This should call checkStatus again

      expect(notifier.debugState, const AsyncValue<bool>.data(true));
      verify(mockFunctions.check()).called(2); // Called once initially, once by requestPermission
    });
  });

  // Example of testing one of the actual providers (e.g., usageStatsPermissionProvider)
  // This requires more setup if we want to mock the static channel methods.
  // A simpler way is to trust that PermissionStatusNotifier works (tested above)
  // and that the provider correctly instantiates it with the right channel methods.
  // For full end-to-end unit test of the provider, one might use a library like mocktail
  // to mock static methods, or refactor channels to be instance-based and injectable.

  // For now, the tests for PermissionStatusNotifier itself cover the core logic.
  // We can assume the providers are correctly wired if PermissionStatusNotifier is solid.
}
