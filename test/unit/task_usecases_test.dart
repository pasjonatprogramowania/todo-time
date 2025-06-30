import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';
import 'package:task_time/domain/usecases/add_task_usecase.dart';
import 'package:task_time/domain/usecases/delete_task_usecase.dart';
import 'package:task_time/domain/usecases/get_all_tasks_usecase.dart';
import 'package:task_time/domain/usecases/get_task_by_id_usecase.dart';
import 'package:task_time/domain/usecases/toggle_task_status_usecase.dart';
import 'package:task_time/domain/usecases/update_task_usecase.dart';
import 'package:task_time/domain/usecases/watch_tasks_usecase.dart';
import 'package:uuid/uuid.dart';

// Generate mocks for TaskRepository by running:
// flutter pub run build_runner build --delete-conflicting-outputs
// This will create task_usecases_test.mocks.dart
@GenerateMocks([TaskRepository])
import 'task_usecases_test.mocks.dart'; // Import generated mocks

void main() {
  late MockTaskRepository mockTaskRepository;
  late AddTaskUseCase addTaskUseCase;
  late DeleteTaskUseCase deleteTaskUseCase;
  late GetAllTasksUseCase getAllTasksUseCase;
  late GetTaskByIdUseCase getTaskByIdUseCase;
  late UpdateTaskUseCase updateTaskUseCase;
  late ToggleTaskStatusUseCase toggleTaskStatusUseCase;
  late WatchTasksUseCase watchTasksUseCase;

  setUp(() {
    mockTaskRepository = MockTaskRepository();
    addTaskUseCase = AddTaskUseCase(mockTaskRepository);
    deleteTaskUseCase = DeleteTaskUseCase(mockTaskRepository);
    getAllTasksUseCase = GetAllTasksUseCase(mockTaskRepository);
    getTaskByIdUseCase = GetTaskByIdUseCase(mockTaskRepository);
    updateTaskUseCase = UpdateTaskUseCase(mockTaskRepository);
    toggleTaskStatusUseCase = ToggleTaskStatusUseCase(mockTaskRepository);
    watchTasksUseCase = WatchTasksUseCase(mockTaskRepository);
  });

  final tId = const Uuid().v4();
  final tTaskEntity = TaskEntity(
    id: tId,
    name: 'Test Task',
    category: TaskCategory.importantNotUrgent,
    timeAward: const Duration(minutes: 30),
    createdAt: DateTime.now(),
  );

  group('AddTaskUseCase', () {
    test('should call addTask on the repository with the correct task', () async {
      // Arrange
      when(mockTaskRepository.addTask(any)).thenAnswer((_) async => {});
      // Act
      await addTaskUseCase(tTaskEntity);
      // Assert
      verify(mockTaskRepository.addTask(tTaskEntity));
      verifyNoMoreInteractions(mockTaskRepository);
    });

    test('should throw ArgumentError if task name is empty', () async {
      final invalidTask = tTaskEntity.copyWith(name: '');
      expect(() async => await addTaskUseCase(invalidTask), throwsA(isA<ArgumentError>()));
    });
     test('should throw ArgumentError if timeAward is zero or negative', () async {
      final invalidTaskZeroTime = tTaskEntity.copyWith(timeAward: Duration.zero);
      final invalidTaskNegativeTime = tTaskEntity.copyWith(timeAward: const Duration(minutes: -5));
      expect(() async => await addTaskUseCase(invalidTaskZeroTime), throwsA(isA<ArgumentError>()));
      expect(() async => await addTaskUseCase(invalidTaskNegativeTime), throwsA(isA<ArgumentError>()));
    });
  });

  group('DeleteTaskUseCase', () {
    test('should call deleteTask on the repository with the correct id', () async {
      // Arrange
      when(mockTaskRepository.deleteTask(any)).thenAnswer((_) async => {});
      // Act
      await deleteTaskUseCase(tId);
      // Assert
      verify(mockTaskRepository.deleteTask(tId));
      verifyNoMoreInteractions(mockTaskRepository);
    });
     test('should throw ArgumentError if task ID is empty', () async {
      expect(() async => await deleteTaskUseCase(''), throwsA(isA<ArgumentError>()));
    });
  });

  group('GetAllTasksUseCase', () {
    test('should call getAllTasks on the repository and return a list of tasks', () async {
      // Arrange
      final tasks = [tTaskEntity, tTaskEntity.copyWith(id: '2')];
      when(mockTaskRepository.getAllTasks()).thenAnswer((_) async => tasks);
      // Act
      final result = await getAllTasksUseCase();
      // Assert
      expect(result, tasks);
      verify(mockTaskRepository.getAllTasks());
      verifyNoMoreInteractions(mockTaskRepository);
    });
  });

  group('GetTaskByIdUseCase', () {
    test('should call getTaskById on the repository and return the task', () async {
      // Arrange
      when(mockTaskRepository.getTaskById(any)).thenAnswer((_) async => tTaskEntity);
      // Act
      final result = await getTaskByIdUseCase(tId);
      // Assert
      expect(result, tTaskEntity);
      verify(mockTaskRepository.getTaskById(tId));
      verifyNoMoreInteractions(mockTaskRepository);
    });
     test('should throw ArgumentError if task ID is empty', () async {
      expect(() async => await getTaskByIdUseCase(''), throwsA(isA<ArgumentError>()));
    });
  });

  group('UpdateTaskUseCase', () {
    test('should call updateTask on the repository with the correct task', () async {
      // Arrange
      when(mockTaskRepository.updateTask(any)).thenAnswer((_) async => {});
      // Act
      await updateTaskUseCase(tTaskEntity);
      // Assert
      verify(mockTaskRepository.updateTask(tTaskEntity));
      verifyNoMoreInteractions(mockTaskRepository);
    });
    test('should throw ArgumentError if task name is empty for update', () async {
      final invalidTask = tTaskEntity.copyWith(name: '');
      expect(() async => await updateTaskUseCase(invalidTask), throwsA(isA<ArgumentError>()));
    });
     test('should throw ArgumentError if task ID is empty for update', () async {
      final invalidTask = tTaskEntity.copyWith(id: '');
      expect(() async => await updateTaskUseCase(invalidTask), throwsA(isA<ArgumentError>()));
    });
  });

  group('ToggleTaskStatusUseCase', () {
    test('should call toggleTaskStatus on the repository with the correct id', () async {
      // Arrange
      when(mockTaskRepository.toggleTaskStatus(any)).thenAnswer((_) async => {});
      // Act
      await toggleTaskStatusUseCase(tId);
      // Assert
      verify(mockTaskRepository.toggleTaskStatus(tId));
      verifyNoMoreInteractions(mockTaskRepository);
    });
    test('should throw ArgumentError if task ID is empty for toggle', () async {
      expect(() async => await toggleTaskStatusUseCase(''), throwsA(isA<ArgumentError>()));
    });
  });

  group('WatchTasksUseCase', () {
    test('should call watchTasks on the repository and return a stream of tasks', () {
      // Arrange
      final tasks = [tTaskEntity];
      // For TaskRepositoryImpl, tasksStream is used which combines initial + watch
      // If testing generic TaskRepository, just mock watchTasks()
      if (mockTaskRepository is MockTaskRepository) { // Check if it's the mock
         when((mockTaskRepository as MockTaskRepository).watchTasks()).thenAnswer((_) => Stream.value(tasks));
         // If your mockTaskRepository needs to behave like TaskRepositoryImpl for tasksStream
         // you might need a more complex mock or test TaskRepositoryImpl directly in an integration test.
         // For this unit test, we assume watchTasks() is the direct interface or tasksStream is handled by it.
      }


      // Act
      final resultStream = watchTasksUseCase();
      // Assert
      expect(resultStream, isA<Stream<List<TaskEntity>>>());
      verify(mockTaskRepository.watchTasks()); // Or tasksStream if that's what WatchTasksUseCase calls
      verifyNoMoreInteractions(mockTaskRepository);

      // Optionally, test the stream content if mock setup allows
      // resultStream.listen(
      //   expectAsync1((event) {
      //     expect(event, tasks);
      //   }),
      // );
    });
  });
}
