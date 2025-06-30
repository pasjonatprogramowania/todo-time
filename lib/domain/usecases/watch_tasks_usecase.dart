import 'dart:async';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';

class WatchTasksUseCase {
  final TaskRepository _repository;

  WatchTasksUseCase(this._repository);

  Stream<List<TaskEntity>> call() {
    // The repository implementation already returns a stream that emits the current list first.
    // If it didn't, we might combine an initial fetch with the watch stream.
    if (_repository is TaskRepositoryImpl) {
        // Accessing the specific stream from Impl which includes initial data
        return (_repository as TaskRepositoryImpl).tasksStream;
    }
    // Fallback or more generic approach if the repository doesn't guarantee initial data on watch
    // This might involve an initial call to getAllTasks and then merging with the watch stream,
    // but the current TaskRepositoryImpl handles this.
    return _repository.watchTasks();
  }
}
