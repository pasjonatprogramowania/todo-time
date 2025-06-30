import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/domain/usecases/add_task_usecase.dart';
import 'package:task_time/domain/usecases/delete_task_usecase.dart';
import 'package:task_time/domain/usecases/get_all_tasks_usecase.dart';
import 'package:task_time/domain/usecases/get_task_by_id_usecase.dart';
import 'package:task_time/domain/usecases/toggle_task_status_usecase.dart';
import 'package:task_time/domain/usecases/update_task_usecase.dart';
import 'package:task_time/domain/usecases/watch_tasks_usecase.dart';
import 'package:task_time/presentation/providers/repository_providers.dart'; // For taskRepositoryProvider

// Add Task UseCase Provider
final addTaskUseCaseProvider = Provider<AddTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return AddTaskUseCase(repository);
});

// Delete Task UseCase Provider
final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return DeleteTaskUseCase(repository);
});

// Get All Tasks UseCase Provider
final getAllTasksUseCaseProvider = Provider<GetAllTasksUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetAllTasksUseCase(repository);
});

// Get Task By Id UseCase Provider
final getTaskByIdUseCaseProvider = Provider<GetTaskByIdUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTaskByIdUseCase(repository);
});

// Update Task UseCase Provider
final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return UpdateTaskUseCase(repository);
});

// Toggle Task Status UseCase Provider
final toggleTaskStatusUseCaseProvider = Provider<ToggleTaskStatusUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return ToggleTaskStatusUseCase(repository);
});

// Watch Tasks UseCase Provider (provides the use case itself)
final watchTasksUseCaseProvider = Provider<WatchTasksUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return WatchTasksUseCase(repository);
});

// StreamProvider for watching all tasks - this is what the UI will typically use
final tasksStreamProvider = StreamProvider.autoDispose((ref) {
  final watchTasksUseCase = ref.watch(watchTasksUseCaseProvider);
  return watchTasksUseCase();
});

// Reset Tasks Status UseCase Provider
final resetTasksStatusUseCaseProvider = Provider<ResetTasksStatusUseCase>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return ResetTasksStatusUseCase(repository);
});
