import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/pages/dashboard/dashboard_page.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}
// Mock for ToggleTaskStatusUseCase (needed by TaskListTile, which is part of DashboardPage)
class MockToggleTaskStatusUseCase extends Mock implements ToggleTaskStatusUseCase {}


void main() {
  late MockGoRouter mockGoRouter;
  late MockToggleTaskStatusUseCase mockToggleTaskStatusUseCase;

  final tasks = [
    TaskEntity(id: '1', name: 'Dashboard Task 1', category: TaskCategory.urgentImportant, timeAward: const Duration(minutes: 10), createdAt: DateTime.now()),
    TaskEntity(id: '2', name: 'Dashboard Task 2', category: TaskCategory.importantNotUrgent, timeAward: const Duration(minutes: 20), createdAt: DateTime.now()),
  ];

  setUp(() {
    mockGoRouter = MockGoRouter();
    mockToggleTaskStatusUseCase = MockToggleTaskStatusUseCase();
    when(mockToggleTaskStatusUseCase.call(any)).thenAnswer((_) async {});
    when(mockGoRouter.go(any)).thenReturn(null); // For context.go('/settings')
    when(mockGoRouter.goNamed(any, extra: anyNamed('extra'), pathParameters: anyNamed('pathParameters')))
        .thenReturn(null); // For context.goNamed('task_form')
  });

  Widget createWidgetUnderTest({required Stream<List<TaskEntity>> tasksStream}) {
    return ProviderScope(
      overrides: [
        tasksStreamProvider.overrideWith((ref) => tasksStream),
        // TaskListTile uses toggleTaskStatusUseCaseProvider.
        // Override it here so TaskListTile within DashboardPage can function.
        toggleTaskStatusUseCaseProvider.overrideWithValue(mockToggleTaskStatusUseCase),
      ],
      child: MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: const DashboardPage(),
        ),
      ),
    );
  }

  group('DashboardPage Widget Tests', () {
    testWidgets('renders app bar, date, and screen time placeholder', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));
      streamController.add([]); // Add empty list to resolve initial loading
      await tester.pump();

      expect(find.text('TaskTime Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.textContaining(RegExp(r'\w{3}, \w{3} \d{1,2}, \d{4}')), findsOneWidget); // Date format
      expect(find.text('Screen Time Remaining:'), findsOneWidget);
      expect(find.text('00h 00m 00s'), findsOneWidget); // Placeholder time
    });

    testWidgets('displays "No tasks yet" when task list is empty', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));

      // Emit empty list
      streamController.add([]);
      await tester.pump(); // Let StreamProvider update

      expect(find.text('No tasks yet. Add one!'), findsOneWidget);
    });

    testWidgets('displays list of tasks when tasks are available', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));

      streamController.add(tasks);
      await tester.pump();

      expect(find.text('Dashboard Task 1'), findsOneWidget);
      expect(find.text('Dashboard Task 2'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('FAB navigates to task_form screen', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));
      streamController.add([]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      verify(mockGoRouter.goNamed('task_form')).called(1);
    });

    testWidgets('Settings icon navigates to settings screen', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));
      streamController.add([]);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      verify(mockGoRouter.go('/settings')).called(1);
    });

    testWidgets('shows loading indicator while tasks are loading', (WidgetTester tester) async {
      // Create a stream that doesn't emit immediately
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));
      // Don't add data to streamController yet
      await tester.pump(); // Initial pump

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Then emit data to remove loading
      streamController.add([]);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when task stream has error', (WidgetTester tester) async {
      final streamController = StreamController<List<TaskEntity>>();
      addTearDown(streamController.close);

      await tester.pumpWidget(createWidgetUnderTest(tasksStream: streamController.stream));

      streamController.addError(Exception('Failed to load tasks'));
      await tester.pump();

      expect(find.textContaining('Error loading tasks:'), findsOneWidget);
    });
  });
}
