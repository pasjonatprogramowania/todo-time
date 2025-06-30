import 'package:flutter_test/flutter_test.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/data/models/task_model.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('TaskEntity', () {
    final uuid = const Uuid().v4();
    final now = DateTime.now();
    final initialTask = TaskEntity(
      id: uuid,
      name: 'Test Task',
      description: 'Test Description',
      category: TaskCategory.importantNotUrgent,
      timeAward: const Duration(minutes: 30),
      isCompleted: false,
      createdAt: now,
      dueDate: now.add(const Duration(days: 1)),
    );

    test('should create a TaskEntity instance', () {
      expect(initialTask.id, uuid);
      expect(initialTask.name, 'Test Task');
      expect(initialTask.isCompleted, false);
    });

    test('copyWith should create a new instance with updated values', () {
      final updatedTask = initialTask.copyWith(
        name: 'Updated Task Name',
        isCompleted: true,
      );

      expect(updatedTask.id, initialTask.id);
      expect(updatedTask.name, 'Updated Task Name');
      expect(updatedTask.isCompleted, true);
      expect(updatedTask.description, initialTask.description); // Unchanged
    });

     test('copyWith should handle null description', () {
      final taskWithNullDesc = TaskEntity(
        id: uuid,
        name: 'Test Task no desc',
        category: TaskCategory.urgentImportant,
        timeAward: const Duration(minutes: 15),
        createdAt: now,
      );
      final copiedTask = taskWithNullDesc.copyWith(name: "Still no desc");
      expect(copiedTask.description, isNull);
    });

    test('copyWith setDueDateToNull should set dueDate to null', () {
      final updatedTask = initialTask.copyWith(setDueDateToNull: true);
      expect(updatedTask.dueDate, isNull);
    });

    test('equality comparison should work correctly', () {
      final task1 = TaskEntity(
        id: '1',
        name: 'Task 1',
        category: TaskCategory.importantNotUrgent,
        timeAward: const Duration(minutes: 10),
        createdAt: DateTime(2023),
      );
      final task2 = TaskEntity(
        id: '1',
        name: 'Task 1',
        category: TaskCategory.importantNotUrgent,
        timeAward: const Duration(minutes: 10),
        createdAt: DateTime(2023),
      );
      final task3 = task1.copyWith(name: 'Changed Task 1');

      expect(task1, task2);
      expect(task1 == task2, isTrue);
      expect(task1.hashCode, task2.hashCode);
      expect(task1 == task3, isFalse);
      expect(task1.hashCode == task3.hashCode, isFalse); // Hash codes should differ if content differs
    });
  });

  group('TaskModel', () {
    final uuid = const Uuid().v4();
    final now = DateTime.now();
    final taskEntity = TaskEntity(
      id: uuid,
      name: 'Entity Task',
      description: 'Entity Description',
      category: TaskCategory.urgentNotImportant,
      timeAward: const Duration(minutes: 45),
      isCompleted: true,
      createdAt: now,
      dueDate: now.add(const Duration(days: 2)),
    );

    test('fromEntity should correctly convert TaskEntity to TaskModel', () {
      final taskModel = TaskModel.fromEntity(taskEntity);

      expect(taskModel.id, taskEntity.id);
      expect(taskModel.name, taskEntity.name);
      expect(taskModel.description, taskEntity.description);
      expect(taskModel.category, taskEntity.category);
      expect(taskModel.timeAwardInMinutes, taskEntity.timeAward.inMinutes);
      expect(taskModel.isCompleted, taskEntity.isCompleted);
      expect(taskModel.createdAt, taskEntity.createdAt);
      expect(taskModel.dueDate, taskEntity.dueDate);
    });

    test('toEntity should correctly convert TaskModel to TaskEntity', () {
      final taskModel = TaskModel(
        id: uuid,
        name: 'Model Task',
        description: 'Model Description',
        category: TaskCategory.notUrgentNotImportant,
        timeAwardInMinutes: 60,
        isCompleted: false,
        createdAt: now,
        dueDate: now.add(const Duration(days: 3)),
      );

      final convertedEntity = taskModel.toEntity();

      expect(convertedEntity.id, taskModel.id);
      expect(convertedEntity.name, taskModel.name);
      expect(convertedEntity.description, taskModel.description);
      expect(convertedEntity.category, taskModel.category);
      expect(convertedEntity.timeAward, Duration(minutes: taskModel.timeAwardInMinutes));
      expect(convertedEntity.isCompleted, taskModel.isCompleted);
      expect(convertedEntity.createdAt, taskModel.createdAt);
      expect(convertedEntity.dueDate, taskModel.dueDate);
    });
  });

  group('TaskCategoryAdapter', () {
    // This is a simple test for the adapter. More thorough testing would involve
    // mocking Hive's BinaryReader/Writer, but for this adapter, checking
    // all values should be sufficient to ensure indices are stable.
    test('should correctly write and read all TaskCategory values', () {
      final adapter = TaskCategoryAdapter();

      for (var category in TaskCategory.values) {
        // Simulate write and read
        final writer = BinaryWriterTest();
        adapter.write(writer, category);
        final reader = BinaryReaderTest(writer.getBytes());
        final readCategory = adapter.read(reader);
        expect(readCategory, category);
      }
    });
  });
}

// Helper classes for testing TypeAdapter read/write
class BinaryWriterTest implements BinaryWriter {
  final List<int> _bytes = [];

  @override
  void writeByte(int byte) {
    _bytes.add(byte);
  }

  Uint8List getBytes() => Uint8List.fromList(_bytes);

  @override
  void write(value, {bool writeTypeId = true}) {
    throw UnimplementedError();
  }
  @override
  void writeInt(int value) => throw UnimplementedError();
  @override
  void writeDouble(double value) => throw UnimplementedError();
  @override
  void writeBool(bool value) => throw UnimplementedError();
  @override
  void writeString(String value, {int? byteCount, bool writeByteCount = true}) => throw UnimplementedError();
  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeIntList(List<int> list, {bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeStringList(List<String> list, {bool writeByteCount = true, bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeList(List list, {bool writeTypeId = true, bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeMap(Map map, {bool writeTypeId = true, bool writeLength = true}) => throw UnimplementedError();
  @override
  void writeHiveList(List list, {bool writeTypeId = true}) => throw UnimplementedError();
  @override
  int writeTypeId(int typeId) => throw UnimplementedError();
}

class BinaryReaderTest implements BinaryReader {
  final Uint8List _bytes;
  int _offset = 0;

  BinaryReaderTest(this._bytes);

  @override
  int readByte() {
    return _bytes[_offset++];
  }

  @override
  dynamic read({bool readTypeId = true}) => throw UnimplementedError();
  @override
  int readInt() => throw UnimplementedError();
  @override
  double readDouble() => throw UnimplementedError();
  @override
  bool readBool() => throw UnimplementedError();
  @override
  String readString({int? byteCount, bool readByteCount = true}) => throw UnimplementedError();
  @override
  Uint8List readByteList({bool readLength = true}) => throw UnimplementedError();
  @override
  List<int> readIntList({bool readLength = true}) => throw UnimplementedError();
  @override
  List<double> readDoubleList({bool readLength = true}) => throw UnimplementedError();
  @override
  List<bool> readBoolList({bool readLength = true}) => throw UnimplementedError();
  @override
  List<String> readStringList({bool readByteCount = true, bool readLength = true}) => throw UnimplementedError();
  @override
  List readList({bool readTypeId = true, bool readLength = true}) => throw UnimplementedError();
  @override
  Map readMap({bool readTypeId = true, bool readLength = true}) => throw UnimplementedError();
  @override
  List readHiveList({bool readTypeId = true}) => throw UnimplementedError();
  @override
  int get typeId => throw UnimplementedError();
  @override
  void skip(int bytes) => _offset += bytes;
}
