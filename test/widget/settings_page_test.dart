import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_time/presentation/pages/settings/settings_page.dart';
import 'package:task_time/presentation/providers/permission_providers.dart';
import 'package:task_time/presentation/providers/debug_providers.dart';
import 'package:task_time/services/platform_channels/accessibility_channel.dart';
import 'package:task_time/services/platform_channels/overlay_channel.dart';
import 'package:task_time/services/platform_channels/usage_stats_channel.dart';

// Mocks for Notifiers - needed to control their state
class MockPermissionStatusNotifier extends StateNotifier<AsyncValue<bool>>
    with Mock
    implements PermissionStatusNotifier {
  MockPermissionStatusNotifier(AsyncValue<bool> state) : super(state);

  @override
  Future<void> checkStatus() async {
    // Simulate check
  }
  @override
  Future<void> requestPermission() async {
    // Simulate request
  }
}

class MockUsageStatsDebugNotifier extends StateNotifier<UsageStatsDebugState>
    with Mock
    implements UsageStatsDebugNotifier {
  MockUsageStatsDebugNotifier(UsageStatsDebugState state) : super(state);

  @override
  Future<void> fetchDailyStats() async {
    // Simulate fetch
  }
}

// Mock for platform channels (if testing interactions deeper, not just notifier state)
// For this test, we primarily override the providers with mock notifiers.
// class MockUsageStatsChannel extends Mock implements UsageStatsChannel {}
// class MockOverlayChannel extends Mock implements OverlayChannel {}
// class MockAccessibilityChannel extends Mock implements AccessibilityChannel {}


void main() {
  // Late initialized Mocks for Notifiers
  late MockPermissionStatusNotifier mockUsageStatsPermissionNotifier;
  late MockPermissionStatusNotifier mockOverlayPermissionNotifier;
  late MockPermissionStatusNotifier mockAccessibilityServiceNotifier;
  late MockUsageStatsDebugNotifier mockUsageStatsDebugNotifier;

  setUp(() {
    // Initialize with default states (e.g., loading or specific data)
    mockUsageStatsPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(false));
    mockOverlayPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(false));
    mockAccessibilityServiceNotifier = MockPermissionStatusNotifier(const AsyncValue.data(false));
    mockUsageStatsDebugNotifier = MockUsageStatsDebugNotifier(UsageStatsDebugState());

    // Default behaviors for mocks (can be overridden in tests)
    when(mockUsageStatsPermissionNotifier.checkStatus()).thenAnswer((_) async {});
    when(mockUsageStatsPermissionNotifier.requestPermission()).thenAnswer((_) async {});
    when(mockOverlayPermissionNotifier.checkStatus()).thenAnswer((_) async {});
    when(mockOverlayPermissionNotifier.requestPermission()).thenAnswer((_) async {});
    when(mockAccessibilityServiceNotifier.checkStatus()).thenAnswer((_) async {});
    when(mockAccessibilityServiceNotifier.requestPermission()).thenAnswer((_) async {});
    when(mockUsageStatsDebugNotifier.fetchDailyStats()).thenAnswer((_) async {});

  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        usageStatsPermissionProvider.overrideWithValue(mockUsageStatsPermissionNotifier),
        overlayPermissionProvider.overrideWithValue(mockOverlayPermissionNotifier),
        accessibilityServiceEnabledProvider.overrideWithValue(mockAccessibilityServiceNotifier),
        usageStatsDebugProvider.overrideWithValue(mockUsageStatsDebugNotifier),
        // foregroundAppStreamProvider can be overridden with a test stream if needed
        foregroundAppStreamProvider.overrideWith((ref) => Stream.value("com.example.foregroundapp"))
      ],
      child: const MaterialApp(
        home: SettingsPage(),
      ),
    );
  }

  group('SettingsPage Widget Tests', () {
    testWidgets('renders settings options and permission tiles', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Settings'), findsOneWidget); // AppBar title
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('App Permissions'), findsOneWidget);
      expect(find.text('Usage Stats Access'), findsOneWidget);
      expect(find.text('Display Over Other Apps'), findsOneWidget);
      expect(find.text('Accessibility Service'), findsOneWidget);
      expect(find.text('Block Schedule'), findsOneWidget);
      expect(find.text('Debug Options'), findsOneWidget);
      expect(find.text('Fetch Daily Usage Stats'), findsOneWidget);
      expect(find.text('Live Foreground App:'), findsOneWidget);
      expect(find.text('com.example.foregroundapp'), findsOneWidget); // From mocked stream
    });

    testWidgets('permission tiles show correct status (e.g., Not Granted)', (WidgetTester tester) async {
      // Notifiers are initialized with AsyncValue.data(false) in setUp
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Status: Not Granted'), findsNWidgets(3)); // For all 3 permissions
      expect(find.widgetWithText(ElevatedButton, 'Grant'), findsNWidgets(3));
    });

    testWidgets('permission tiles show correct status (e.g., Granted)', (WidgetTester tester) async {
      // Override one notifier to return true
      when(mockUsageStatsPermissionNotifier.state).thenReturn(const AsyncValue.data(true));
      // Need to rebuild the notifier or re-override the provider for state to change in widget
      mockUsageStatsPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(true));
      when(mockUsageStatsPermissionNotifier.checkStatus()).thenAnswer((_) async {});
      when(mockUsageStatsPermissionNotifier.requestPermission()).thenAnswer((_) async {});


      await tester.pumpWidget(
         ProviderScope(
          overrides: [
            usageStatsPermissionProvider.overrideWithValue(mockUsageStatsPermissionNotifier), // new instance
            overlayPermissionProvider.overrideWithValue(mockOverlayPermissionNotifier),
            accessibilityServiceEnabledProvider.overrideWithValue(mockAccessibilityServiceNotifier),
            usageStatsDebugProvider.overrideWithValue(mockUsageStatsDebugNotifier),
            foregroundAppStreamProvider.overrideWith((ref) => Stream.value("com.example.foregroundapp"))
          ],
          child: const MaterialApp(home: SettingsPage()),
        )
      );
      await tester.pumpAndSettle();


      expect(find.text('Status: Granted'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Grant'), findsNWidgets(2)); // Other two are still false
    });

    testWidgets('tapping "Grant" button on permission tile calls requestPermission', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find the "Grant" button for Usage Stats (assuming it's the first one)
      final grantButton = find.widgetWithText(ElevatedButton, 'Grant').first;
      await tester.tap(grantButton);
      await tester.pump();

      verify(mockUsageStatsPermissionNotifier.requestPermission()).called(1);
    });

    testWidgets('tapping "Fetch Daily Usage Stats" calls fetchDailyStats if permission granted', (WidgetTester tester) async {
      // Set UsageStats permission to granted
      mockUsageStatsPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(true));
      when(mockUsageStatsPermissionNotifier.checkStatus()).thenAnswer((_) async {});
      when(mockUsageStatsPermissionNotifier.requestPermission()).thenAnswer((_) async {});


      await tester.pumpWidget(
         ProviderScope(
          overrides: [
            usageStatsPermissionProvider.overrideWithValue(mockUsageStatsPermissionNotifier),
            overlayPermissionProvider.overrideWithValue(mockOverlayPermissionNotifier),
            accessibilityServiceEnabledProvider.overrideWithValue(mockAccessibilityServiceNotifier),
            usageStatsDebugProvider.overrideWithValue(mockUsageStatsDebugNotifier),
            foregroundAppStreamProvider.overrideWith((ref) => Stream.value("com.example.foregroundapp"))
          ],
          child: const MaterialApp(home: SettingsPage()),
        )
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fetch Daily Usage Stats'));
      await tester.pump();

      verify(mockUsageStatsDebugNotifier.fetchDailyStats()).called(1);
    });

     testWidgets('tapping "Fetch Daily Usage Stats" shows snackbar if permission not granted', (WidgetTester tester) async {
      // UsageStats permission is false by default from setUp
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Fetch Daily Usage Stats'));
      await tester.pump(); // For SnackBar to appear

      verifyNever(mockUsageStatsDebugNotifier.fetchDailyStats());
      expect(find.text('Usage Stats permission not granted. Please grant it first.'), findsOneWidget);
    });


    testWidgets('displays loading indicator when fetching usage stats', (WidgetTester tester) async {
      mockUsageStatsPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(true)); // Permission granted
      when(mockUsageStatsPermissionNotifier.checkStatus()).thenAnswer((_) async {});
      when(mockUsageStatsDebugNotifier.state).thenReturn(UsageStatsDebugState(isLoading: true)); // Simulate loading

      await tester.pumpWidget(createWidgetUnderTest());

      // The button itself doesn't show loading, but the list below it does
      // This test assumes the state is already isLoading when widget builds
      // A better test would be to tap the button and then check for loading state change.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays usage stats when available', (WidgetTester tester) async {
      mockUsageStatsPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(true));
      when(mockUsageStatsPermissionNotifier.checkStatus()).thenAnswer((_) async {});

      final stats = {'com.app.one': const Duration(minutes: 10), 'com.app.two': const Duration(seconds: 75)};
      when(mockUsageStatsDebugNotifier.state).thenReturn(UsageStatsDebugState(stats: stats));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Usage Stats (2 apps):'), findsOneWidget);
      expect(find.text('com.app.one'), findsOneWidget);
      expect(find.text('10 min 0s'), findsOneWidget);
      expect(find.text('com.app.two'), findsOneWidget);
      expect(find.text('1 min 15s'), findsOneWidget);
    });

    testWidgets('Test Lock Screen Overlay button calls OverlayChannel.showOverlay', (WidgetTester tester) async {
      // Assume overlay permission is granted
      mockOverlayPermissionNotifier = MockPermissionStatusNotifier(const AsyncValue.data(true));
      when(mockOverlayPermissionNotifier.checkStatus()).thenAnswer((_) async {});

      // We need to mock the static OverlayChannel.showOverlay or test its effects
      // This is difficult with static methods.
      // For this test, we'll assume it can be called and doesn't crash.
      // A full integration test would be better.

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();


      // Verify OverlayChannel.showOverlay is called.
      // This requires setting up MethodChannel mocks.
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessenger.instance.setMockMethodCallHandler(OverlayChannel.platform, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'showOverlay') {
          return true;
        }
        return null;
      });


      await tester.tap(find.text('Test Lock Screen Overlay'));
      await tester.pumpAndSettle();

      expect(log, <Matcher>[isMethodCall('showOverlay', arguments: null)]);
      log.clear();
      TestDefaultBinaryMessenger.instance.setMockMethodCallHandler(OverlayChannel.platform, null);
    });

  });
}
