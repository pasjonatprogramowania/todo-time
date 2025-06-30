import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';

class GetTaskByIdUseCase {
  final TaskRepository _repository;

  GetTaskByIdUseCase(this._repository);

  Future<TaskEntity?> call(String taskId) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty.');
    }
    return await _repository.getTaskById(taskId);
  }
}
