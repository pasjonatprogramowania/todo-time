import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/pages/task_form/task_form_page.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

// Mocks
class MockAddTaskUseCase extends Mock implements AddTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockAddTaskUseCase mockAddTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockAddTaskUseCase = MockAddTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();
    mockGoRouter = MockGoRouter();

    when(mockAddTaskUseCase.call(any)).thenAnswer((_) async {});
    when(mockUpdateTaskUseCase.call(any)).thenAnswer((_) async {});
    when(mockGoRouter.pop()).thenReturn(null); // Mock void return for pop
  });

  Widget createWidgetUnderTest({TaskEntity? task}) {
    return ProviderScope(
      overrides: [
        addTaskUseCaseProvider.overrideWithValue(mockAddTaskUseCase),
        updateTaskUseCaseProvider.overrideWithValue(mockUpdateTaskUseCase),
      ],
      child: MaterialApp(
        home: InheritedGoRouter(
          goRouter: mockGoRouter,
          child: TaskFormPage(task: task),
        ),
      ),
    );
  }

  group('TaskFormPage Widget Tests', () {
    testWidgets('renders correctly for adding a new task', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Add Task'), findsOneWidget); // AppBar title
      expect(find.widgetWithText(TextFormField, 'Task Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Description (Optional)'), findsOneWidget);
      expect(find.widgetWithText(DropdownButtonFormField<TaskCategory>, 'Category (Eisenhower Matrix)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Time Award (minutes)'), findsOneWidget);
      expect(find.text('No Due Date'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.save), findsOneWidget);
      expect(find.text('Add Task'), findsNWidgets(2)); // Button text and AppBar title
    });

    testWidgets('renders correctly for editing an existing task', (WidgetTester tester) async {
      final existingTask = TaskEntity(
        id: const Uuid().v4(),
        name: 'Existing Task',
        description: 'Existing Desc',
        category: TaskCategory.urgentImportant,
        timeAward: const Duration(minutes: 60),
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 5)),
      );
      await tester.pumpWidget(createWidgetUnderTest(task: existingTask));

      expect(find.text('Edit Task'), findsOneWidget); // AppBar title
      expect(find.text('Existing Task'), findsOneWidget); // Name field prefilled
      expect(find.text('Existing Desc'), findsOneWidget); // Description field prefilled
      expect(find.text('60'), findsOneWidget); // Time award field prefilled
      expect(find.textContaining('Due Date:'), findsOneWidget); // Due date prefilled
      // Check if correct category is selected in dropdown
      final dropdown = tester.widget<DropdownButtonFormField<TaskCategory>>(
          find.byWidgetPredicate((widget) => widget is DropdownButtonFormField<TaskCategory>));
      expect(dropdown.value, TaskCategory.urgentImportant);
      expect(find.text('Save Changes'), findsOneWidget); // Button text
    });

    testWidgets('shows validation error for empty task name', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.save));
      await tester.pump(); // Trigger validation

      expect(find.text('Please enter a task name'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid time award', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.widgetWithText(TextFormField, 'Task Name'), 'Valid Name');
      await tester.enterText(find.widgetWithText(TextFormField, 'Time Award (minutes)'), '0');

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.save));
      await tester.pump();

      expect(find.text('Please enter a positive number of minutes'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Time Award (minutes)'), '-5');
      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.save));
      await tester.pump();
      expect(find.text('Please enter a positive number of minutes'), findsOneWidget);
    });

    testWidgets('calls AddTaskUseCase on submit for new task', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.widgetWithText(TextFormField, 'Task Name'), 'New Awesome Task');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description (Optional)'), 'With details');
      await tester.enterText(find.widgetWithText(TextFormField, 'Time Award (minutes)'), '25');
      // Select category (assuming default is fine or tap to change if needed)
      // Select due date (optional)

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.save));
      await tester.pumpAndSettle(); // Allow async operations to complete

      verify(mockAddTaskUseCase.call(any)).called(1);
      verify(mockGoRouter.pop()).called(1); // Check if it navigates back
    });

    testWidgets('calls UpdateTaskUseCase on submit for existing task', (WidgetTester tester) async {
       final existingTask = TaskEntity(
        id: const Uuid().v4(),
        name: 'Old Task Name',
        category: TaskCategory.importantNotUrgent,
        timeAward: const Duration(minutes: 30),
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(createWidgetUnderTest(task: existingTask));

      await tester.enterText(find.widgetWithText(TextFormField, 'Task Name'), 'Updated Task Name');
      // Other fields can be modified similarly

      await tester.tap(find.widgetWithIcon(ElevatedButton, Icons.save));
      await tester.pumpAndSettle();

      verify(mockUpdateTaskUseCase.call(any)).called(1);
      verify(mockGoRouter.pop()).called(1);
    });

    testWidgets('selecting a due date updates the UI', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('No Due Date'), findsOneWidget);
      await tester.tap(find.text('Tap to select a due date')); // Or find by Icon
      await tester.pumpAndSettle(); // Date picker appears

      // Simulate selecting a date
      // This part is tricky as it involves interacting with system dialogs.
      // A common approach is to mock the showDatePicker function if possible,
      // or test the logic that handles the picked date separately.
      // For this test, we'll assume the dialog interaction.
      await tester.tap(find.text('OK')); // Or select a specific day and tap OK
      await tester.pumpAndSettle(); // Date picker disappears

      expect(find.textContaining('Due Date:'), findsOneWidget);
      expect(find.text('Clear Due Date'), findsOneWidget);

      // Test clearing due date
      await tester.tap(find.text('Clear Due Date'));
      await tester.pumpAndSettle();
      expect(find.text('No Due Date'), findsOneWidget);
      expect(find.text('Clear Due Date'), findsNothing);

    });

    testWidgets('selecting a category updates the internal state', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find the DropdownButtonFormField
      final dropdownFinder = find.byWidgetPredicate(
        (Widget widget) => widget is DropdownButtonFormField<TaskCategory> && widget.decoration?.labelText == 'Category (Eisenhower Matrix)',
      );
      expect(dropdownFinder, findsOneWidget);

      // Tap the dropdown to open it
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle(); // Wait for the dropdown items to appear

      // Find and tap a specific category item
      // Example: Tap 'UrgentImportant'. The text depends on how TaskCategory enum is stringified.
      // For `category.toString().split('.').last` it would be 'urgentImportant'
      final categoryToSelectText = TaskCategory.urgentImportant.toString().split('.').last;
      await tester.tap(find.text(categoryToSelectText).last); // .last if multiple similar texts
      await tester.pumpAndSettle(); // Wait for the dropdown to close and UI to update

      // Verify the selected category in the widget's state (requires access to state or checking dropdown value)
      final dropdown = tester.widget<DropdownButtonFormField<TaskCategory>>(dropdownFinder);
      expect(dropdown.value, TaskCategory.urgentImportant);
    });
  });
}
