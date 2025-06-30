import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';

class AddTaskUseCase {
  final TaskRepository _repository;

  AddTaskUseCase(this._repository);

  Future<void> call(TaskEntity task) async {
    // Basic validation or business logic can go here
    if (task.name.isEmpty) {
      throw ArgumentError('Task name cannot be empty.');
    }
    if (task.timeAward.isNegative || task.timeAward == Duration.zero) {
      // Or handle this differently, e.g. default duration
      throw ArgumentError('Time award must be a positive duration.');
    }
    // Ensure ID is unique, often generated here or by the repository
    // For simplicity, assuming TaskEntity comes with an ID (e.g., UUID)
    await _repository.addTask(task);
  }
}
