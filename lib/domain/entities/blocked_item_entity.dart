import 'package:hive/hive.dart';

part 'blocked_item_entity.g.dart'; // For Hive generation

@HiveType(typeId: 5) // Ensure unique typeId
class BlockedAppEntity extends HiveObject {
  @HiveField(0)
  final String packageName; // e.g., com.instagram.android

  @HiveField(1)
  final String appName; // User-friendly name, e.g., Instagram

  // iconData might be tricky to store directly in Hive efficiently without conversion.
  // Storing as Uint8List if we fetch and save the icon bytes, or just rely on fetching it live.
  // For simplicity, we'll omit icon storage in Hive for now and fetch live if needed.

  BlockedAppEntity({required this.packageName, required this.appName});

  @override
  String toString() => 'BlockedAppEntity(packageName: $packageName, appName: $appName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedAppEntity &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

@HiveType(typeId: 6) // Ensure unique typeId
class BlockedWebsiteEntity extends HiveObject {
  @HiveField(0)
  final String url; // e.g., youtube.com (will need normalization)

  BlockedWebsiteEntity({required this.url});

   @override
  String toString() => 'BlockedWebsiteEntity(url: $url)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedWebsiteEntity &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

// A container for all blocked items, could be a Hive object itself.
@HiveType(typeId: 7)
class BlockedItemsList extends HiveObject {
  @HiveField(0)
  List<BlockedAppEntity> apps;

  @HiveField(1)
  List<BlockedWebsiteEntity> websites;

  BlockedItemsList({
    List<BlockedAppEntity>? apps,
    List<BlockedWebsiteEntity>? websites,
  }) : apps = apps ?? [], websites = websites ?? [];

  factory BlockedItemsList.empty() {
    return BlockedItemsList(apps: [], websites: []);
  }
}
