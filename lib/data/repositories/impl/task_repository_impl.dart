import 'dart:async';
import 'package:hive/hive.dart';
import 'package:task_time/data/models/task_model.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/repositories/task_repository.dart';
import 'package:task_time/main.dart'; // For tasksBoxName

class TaskRepositoryImpl implements TaskRepository {
  final Box<TaskModel> _taskBox;

  TaskRepositoryImpl() : _taskBox = Hive.box<TaskModel>(tasksBoxName);

  @override
  Future<void> addTask(TaskEntity taskEntity) async {
    final taskModel = TaskModel.fromEntity(taskEntity);
    await _taskBox.put(taskModel.id, taskModel);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    return _taskBox.values.map((model) => model.toEntity()).toList();
  }

  @override
  Future<TaskEntity?> getTaskById(String id) async {
    final taskModel = _taskBox.get(id);
    return taskModel?.toEntity();
  }

  @override
  Future<void> updateTask(TaskEntity taskEntity) async {
    final taskModel = TaskModel.fromEntity(taskEntity);
    if (_taskBox.containsKey(taskModel.id)) {
      await _taskBox.put(taskModel.id, taskModel);
    } else {
      throw Exception("Task with id ${taskModel.id} not found for update.");
    }
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    final taskModel = _taskBox.get(id);
    if (taskModel != null) {
      taskModel.isCompleted = !taskModel.isCompleted;
      await taskModel.save(); // HiveObjects can be saved directly
    } else {
      throw Exception("Task with id $id not found for toggling status.");
    }
  }

  @override
  Stream<List<TaskEntity>> watchTasks() {
    // Listen to the box's stream for changes
    return _taskBox.watch().map((event) {
      // event.key, event.value, event.deleted
      // When any change occurs, we refetch all tasks.
      // For more granular updates, one might inspect event.value and event.deleted.
      return _taskBox.values.map((model) => model.toEntity()).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by newest first
    });
  }

  // Helper to initially populate the stream or if the box is empty
  // This emits the current list first, then updates on changes.
  Stream<List<TaskEntity>> get tasksStream async* {
    yield _taskBox.values.map((model) => model.toEntity()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Initial data
    yield* watchTasks(); // Subsequent updates
  }
}
