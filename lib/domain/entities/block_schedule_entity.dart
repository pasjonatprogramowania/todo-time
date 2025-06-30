import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:hive/hive.dart';

part 'block_schedule_entity.g.dart'; // For Hive generation

// Represents a single day's schedule
@HiveType(typeId: 3) // Ensure unique typeId
class BlockScheduleEntry extends HiveObject {
  @HiveField(0)
  final int dayOfWeek; // 1 for Monday, 7 for Sunday (DateTime.monday, etc.)

  @HiveField(1)
  bool isEnabled;

  @HiveField(2)
  String? startTime; // Store as "HH:mm" string

  @HiveField(3)
  String? endTime; // Store as "HH:mm" string

  BlockScheduleEntry({
    required this.dayOfWeek,
    this.isEnabled = false,
    this.startTime,
    this.endTime,
  });

  TimeOfDay? get startTimeOfDay {
    if (startTime == null) return null;
    final parts = startTime!.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  set startTimeOfDay(TimeOfDay? time) {
    if (time == null) {
      startTime = null;
    } else {
      startTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }

   TimeOfDay? get endTimeOfDay {
    if (endTime == null) return null;
    final parts = endTime!.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  set endTimeOfDay(TimeOfDay? time) {
    if (time == null) {
      endTime = null;
    } else {
      endTime = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    }
  }
}

// Manages the overall schedule settings (a list of entries)
// This class itself might not need to be a HiveObject if we store a List<BlockScheduleEntry>
// directly in a box, or if it's just a conceptual container.
// For simplicity, we'll manage a Box<BlockScheduleEntry> where keys could be dayOfWeek.
// Or, a single HiveObject holding the list. Let's try the latter for easier top-level access.

@HiveType(typeId: 4) // Ensure unique typeId
class AppBlockSchedule extends HiveObject {
  @HiveField(0)
  List<BlockScheduleEntry> scheduleDays; // List of 7 entries, one for each day

  AppBlockSchedule({required this.scheduleDays});

  // Factory to create a default schedule
  factory AppBlockSchedule.defaultSchedule() {
    return AppBlockSchedule(
      scheduleDays: List.generate(7, (index) {
        // DateTime.monday is 1, Sunday is 7. index is 0-6.
        return BlockScheduleEntry(dayOfWeek: index + 1, isEnabled: false);
      }),
    );
  }
}
