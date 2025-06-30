// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_schedule_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockScheduleEntryAdapter extends TypeAdapter<BlockScheduleEntry> {
  @override
  final int typeId = 3;

  @override
  BlockScheduleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockScheduleEntry(
      dayOfWeek: fields[0] as int,
      isEnabled: fields[1] as bool,
      startTime: fields[2] as String?,
      endTime: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BlockScheduleEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.isEnabled)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockScheduleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppBlockScheduleAdapter extends TypeAdapter<AppBlockSchedule> {
  @override
  final int typeId = 4;

  @override
  AppBlockSchedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppBlockSchedule(
      scheduleDays: (fields[0] as List).cast<BlockScheduleEntry>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppBlockSchedule obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.scheduleDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBlockScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
