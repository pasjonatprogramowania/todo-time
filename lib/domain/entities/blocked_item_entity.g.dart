// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_item_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlockedAppEntityAdapter extends TypeAdapter<BlockedAppEntity> {
  @override
  final int typeId = 5;

  @override
  BlockedAppEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockedAppEntity(
      packageName: fields[0] as String,
      appName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BlockedAppEntity obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.appName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedAppEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockedWebsiteEntityAdapter extends TypeAdapter<BlockedWebsiteEntity> {
  @override
  final int typeId = 6;

  @override
  BlockedWebsiteEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockedWebsiteEntity(
      url: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BlockedWebsiteEntity obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.url);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedWebsiteEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockedItemsListAdapter extends TypeAdapter<BlockedItemsList> {
  @override
  final int typeId = 7;

  @override
  BlockedItemsList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockedItemsList(
      apps: (fields[0] as List).cast<BlockedAppEntity>(),
      websites: (fields[1] as List).cast<BlockedWebsiteEntity>(),
    );
  }

  @override
  void write(BinaryWriter writer, BlockedItemsList obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.apps)
      ..writeByte(1)
      ..write(obj.websites);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedItemsListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
