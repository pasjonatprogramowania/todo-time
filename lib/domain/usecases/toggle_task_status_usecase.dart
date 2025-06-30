import 'package:task_time/domain/repositories/task_repository.dart';

class ToggleTaskStatusUseCase {
  final TaskRepository _repository;

  ToggleTaskStatusUseCase(this._repository);

  Future<void> call(String taskId) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty.');
    }
    await _repository.toggleTaskStatus(taskId);
  }
}
