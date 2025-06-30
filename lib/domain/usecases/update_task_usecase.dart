import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository _repository;

  UpdateTaskUseCase(this._repository);

  Future<void> call(TaskEntity task) async {
    if (task.name.isEmpty) {
      throw ArgumentError('Task name cannot be empty.');
    }
    if (task.id.isEmpty) {
      throw ArgumentError('Task ID cannot be empty for update.');
    }
    await _repository.updateTask(task);
  }
}
