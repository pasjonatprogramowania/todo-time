import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:task_time/presentation/widgets/task_list_tile.dart';
import 'package:go_router/go_router.dart';

// Mock for GoRouter
class MockGoRouter extends Mock implements GoRouter {}

// Mock for ToggleTaskStatusUseCase if needed, but usually we override the provider
class MockToggleTaskStatusUseCase extends Mock implements ToggleTaskStatusUseCase {}


void main() {
  final testTask = TaskEntity(
    id: '1',
    name: 'Test Task Tile',
    description: 'A description for the test task tile.',
    category: TaskCategory.importantNotUrgent,
    timeAward: const Duration(minutes: 30),
    createdAt: DateTime.now(),
    isCompleted: false,
    dueDate: DateTime.now().add(const Duration(days: 1)),
  );

  final completedTestTask = testTask.copyWith(isCompleted: true);

  // Helper to wrap widget in MaterialApp and ProviderScope
  Widget createWidgetUnderTest(TaskEntity task, {GoRouter? goRouter}) {
    final mockGo = goRouter ?? MockGoRouter();
     // Mock the toggle use case provider
    final mockToggleUseCase = MockToggleTaskStatusUseCase();
    when(mockToggleUseCase.call(any)).thenAnswer((_) async => {});


    return ProviderScope(
      overrides: [
        // Override the use case provider if TaskListTile directly uses it.
        // If it uses a more specific provider (e.g. a task specific provider), mock that.
        // Here, toggleTaskStatusUseCaseProvider is used.
        toggleTaskStatusUseCaseProvider.overrideWithValue(mockToggleUseCase),
      ],
      child: MaterialApp(
        home: InheritedGoRouter( // For goNamed to work if TaskListTile uses it
          goRouter: mockGo,
          child: Scaffold(body: TaskListTile(task: task)),
        ),
      ),
    );
  }

  group('TaskListTile Widget Tests', () {
    testWidgets('renders task name, description, time award, and category', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testTask));

      expect(find.text('Test Task Tile'), findsOneWidget);
      expect(find.text('A description for the test task tile.'), findsOneWidget);
      expect(find.text('+30m'), findsOneWidget); // Formatted time award
      expect(find.text('Important Not Urgent'), findsOneWidget); // Formatted category
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('renders due date if available', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(testTask));
      // Assuming default date format
      expect(find.textContaining('Due:'), findsOneWidget);
    });

    testWidgets('does not render due date if null', (WidgetTester tester) async {
      final taskNoDueDate = testTask.copyWith(setDueDateToNull: true);
      await tester.pumpWidget(createWidgetUnderTest(taskNoDueDate));
      expect(find.textContaining('Due:'), findsNothing);
    });

    testWidgets('shows completed state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(completedTestTask));

      expect(find.text('Test Task Tile'), findsOneWidget);
      // Check for line-through style (this is tricky, might need custom finder or check icon)
      final taskNameText = tester.widget<Text>(find.text('Test Task Tile'));
      expect(taskNameText.style?.decoration, TextDecoration.lineThrough);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('tapping checkbox toggles completion status', (WidgetTester tester) async {
       // Use a real provider container to test provider interactions if needed,
       // or mock the specific provider that handles the toggle.
      final mockToggleUseCase = MockToggleTaskStatusUseCase();
      when(mockToggleUseCase.call(testTask.id)).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            toggleTaskStatusUseCaseProvider.overrideWithValue(mockToggleUseCase),
          ],
          child: MaterialApp(
            home: Scaffold(body: TaskListTile(task: testTask)),
          ),
        )
      );

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump(); // Rebuild the widget after state change

      // Verify that the use case was called
      verify(mockToggleUseCase.call(testTask.id)).called(1);
      // The UI itself won't update to completed state unless the stream provider it listens to updates.
      // This test primarily verifies the action dispatch.
    });

    testWidgets('tapping tile navigates to task form for editing', (WidgetTester tester) async {
      final mockGo = MockGoRouter();
      when(mockGo.goNamed(any, extra: anyNamed('extra'))).thenReturn(null); // Mock void return

      await tester.pumpWidget(createWidgetUnderTest(testTask, goRouter: mockGo));

      await tester.tap(find.byType(InkWell)); // Tap the tile
      await tester.pumpAndSettle();

      verify(mockGo.goNamed('task_form', extra: testTask)).called(1);
    });
  });
}
