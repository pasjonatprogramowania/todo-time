import 'package:flutter/foundation.dart'; // For @immutable

enum TaskCategory {
  urgentImportant, // Do now
  importantNotUrgent, // Schedule
  urgentNotImportant, // Delegate
  notUrgentNotImportant, // Delete
}

@immutable
class TaskEntity {
  final String id;
  final String name;
  final String? description;
  final TaskCategory category;
  final Duration timeAward; // Duration of screen time awarded
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? dueDate; // Optional due date

  const TaskEntity({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.timeAward,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  TaskEntity copyWith({
    String? id,
    String? name,
    String? description,
    TaskCategory? category,
    Duration? timeAward,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    bool setDueDateToNull = false,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      timeAward: timeAward ?? this.timeAward,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: setDueDateToNull ? null : (dueDate ?? this.dueDate),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          timeAward == other.timeAward &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          dueDate == other.dueDate;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      timeAward.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      dueDate.hashCode;

  @override
  String toString() {
    return 'TaskEntity{id: $id, name: $name, description: $description, category: $category, timeAward: $timeAward, isCompleted: $isCompleted, createdAt: $createdAt, dueDate: $dueDate}';
  }
}
