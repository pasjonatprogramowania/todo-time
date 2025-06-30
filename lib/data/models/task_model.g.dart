// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 0;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      category: fields[3] as TaskCategory, // This will use TaskCategoryAdapter
      timeAwardInMinutes: fields[4] as int,
      isCompleted: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(8) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category) // This will use TaskCategoryAdapter
      ..writeByte(4)
      ..write(obj.timeAwardInMinutes)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// Note: The TaskCategoryAdapter is defined in task_model.dart itself.
// If it were a separate HiveType enum like HiveTaskCategory,
// its adapter would also be generated here or need to be registered.
// Since TaskCategory is a plain enum and we provided TaskCategoryAdapter,
// Hive will use that for fields of type TaskCategory.
