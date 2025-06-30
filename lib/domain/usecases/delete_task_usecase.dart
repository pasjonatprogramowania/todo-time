import 'package:task_time/domain/repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository _repository;

  DeleteTaskUseCase(this._repository);

  Future<void> call(String taskId) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty.');
    }
    await _repository.deleteTask(taskId);
  }
}
