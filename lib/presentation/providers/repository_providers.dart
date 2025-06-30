import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/data/repositories/impl/task_repository_impl.dart';
import 'package:task_time/domain/repositories/task_repository.dart';

// Provider for TaskRepository implementation
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl();
});
