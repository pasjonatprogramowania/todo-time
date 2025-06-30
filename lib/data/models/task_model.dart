import 'package:hive/hive.dart';
import 'package:task_time/domain/entities/task_entity.dart'; // For TaskCategory enum

part 'task_model.g.dart'; // Hive generator will create this file

@HiveType(typeId: 0) // Unique typeId for Hive
class TaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  TaskCategory category;

  @HiveField(4)
  int timeAwardInMinutes; // Storing Duration as int (minutes) for simplicity with Hive

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? dueDate;

  TaskModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.timeAwardInMinutes,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  // Conversion from TaskEntity to TaskModel
  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      timeAwardInMinutes: entity.timeAward.inMinutes,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      dueDate: entity.dueDate,
    );
  }

  // Conversion from TaskModel to TaskEntity
  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      name: name,
      description: description,
      category: category,
      timeAward: Duration(minutes: timeAwardInMinutes),
      isCompleted: isCompleted,
      createdAt: createdAt,
      dueDate: dueDate,
    );
  }
}

// We also need a TypeAdapter for the TaskCategory enum
// Hive doesn't support enums directly in the way we'd want without an adapter,
// or by storing the index/name. Storing index is more efficient.

@HiveType(typeId: 1) // Unique typeId for Hive
enum HiveTaskCategory {
  @HiveField(0)
  urgentImportant,
  @HiveField(1)
  importantNotUrgent,
  @HiveField(2)
  urgentNotImportant,
  @HiveField(3)
  notUrgentNotImportant,
}

// Adapter for TaskCategory to HiveTaskCategory and back
// This could be part of the TaskModelAdapter generation or a separate one.
// For simplicity, we'll handle this manually in the model or repository layer for now,
// or rely on Hive storing the enum's index if we register the enum itself with an adapter.

// Let's create an adapter for TaskCategory to be used by Hive.
// This requires a separate file or careful structuring if generated.
// For now, let's assume we'll handle enum storage via its index implicitly or define an adapter later.
// The `TaskCategory` enum itself needs an adapter.

class TaskCategoryAdapter extends TypeAdapter<TaskCategory> {
  @override
  final int typeId = 2; // Unique typeId

  @override
  TaskCategory read(BinaryReader reader) {
    return TaskCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, TaskCategory obj) {
    writer.writeByte(obj.index);
  }
}
