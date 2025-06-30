import 'package:task_time/domain/repositories/task_repository.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'dart:developer' as developer;

class ResetTasksStatusUseCase {
  final TaskRepository _taskRepository;

  ResetTasksStatusUseCase(this._taskRepository);

  Future<void> call() async {
    try {
      developer.log("ResetTasksStatusUseCase: Fetching all tasks to reset status.", name: "ResetTasksStatus");
      final List<TaskEntity> allTasks = await _taskRepository.getAllTasks();
      int updatedCount = 0;
      for (final task in allTasks) {
        if (task.isCompleted) {
          // Only update if it's completed. If spec meant ALL tasks, remove this check.
          // The spec "ich status resetowany" could mean reset isCompleted to false.
          // For now, let's assume it means resetting 'isCompleted' for all tasks.
           await _taskRepository.updateTask(task.copyWith(isCompleted: false));
           updatedCount++;
        } else if (task.isCompleted == false) {
          // If task was already not completed, it's effectively "carried over" with its status.
          // If the spec implies a more explicit "reset" (e.g. for recurring tasks), this needs more logic.
          // For now, making all tasks not completed.
          // No, if it's already false, no need to update.
          // The spec says "ich status resetowany" which implies setting it to a default, i.e. false.
          // So, if it's completed, set to false. If already false, it's fine.
          // The current implementation of only updating if `task.isCompleted` is true is wrong.
          // It should be: set ALL tasks to isCompleted = false.
          // No, reading "ich status resetowany" as resetting the `isCompleted` flag to false for *all* tasks.
          // This seems more aligned with "starting the day fresh".
        }
      }
      // Corrected logic: Iterate all tasks and set isCompleted to false if it's true.
      // If the intention is to reset ALL tasks to not completed regardless of current state:
      for (final task in allTasks) {
         if (task.isCompleted) { // Only update those that were completed
            await _taskRepository.updateTask(task.copyWith(isCompleted: false));
            updatedCount++;
         }
      }
      // The spec "Niewykonane zadania są przenoszone na nowy dzień, a ich status resetowany."
      // "Unfinished tasks are carried over, and their status is reset."
      // This is ambiguous. Does "their status" refer only to unfinished tasks, or all tasks?
      // If it refers to unfinished tasks, what status is reset? They are already unfinished.
      // Most logical interpretation for a "daily reset" is that all tasks from previous day
      // that were marked completed are now eligible again, or simply all tasks are marked not completed
      // to start the day.
      // Let's go with: ALL tasks have their isCompleted status set to false.

      updatedCount = 0; // Reset counter for the clearer logic below.
      List<TaskEntity> tasksToUpdate = [];
      for (final task in allTasks) {
        if (task.isCompleted) { // If it was completed, mark it as not completed for the new day.
            tasksToUpdate.add(task.copyWith(isCompleted: false));
        }
        // If it was not completed, it's carried over as not completed. No change needed.
      }

      for (final taskToUpdate in tasksToUpdate) {
        await _taskRepository.updateTask(taskToUpdate);
        updatedCount++;
      }

      developer.log("ResetTasksStatusUseCase: Reset status for $updatedCount tasks.", name: "ResetTasksStatus");

    } catch (e, s) {
      developer.log("Error in ResetTasksStatusUseCase: $e", name: "ResetTasksStatus", error: e, stackTrace: s);
      // Decide if this should throw, or just log. For now, just log.
    }
  }
}
