import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:task_time/domain/entities/block_schedule_entity.dart';
import 'package:task_time/main.dart'; // For blockScheduleBoxName
import 'dart:developer' as developer;

const String _appScheduleKey = 'main_app_block_schedule';

class AppBlockScheduleNotifier extendsStateNotifier<AsyncValue<AppBlockSchedule>> {
  final Box<AppBlockSchedule> _box;

  AppBlockScheduleNotifier(this._box) : super(const AsyncValue.loading()) {
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      state = const AsyncValue.loading();
      AppBlockSchedule? schedule = _box.get(_appScheduleKey);
      if (schedule == null) {
        developer.log("No schedule found in Hive, creating default schedule.", name: "AppBlockScheduleNotifier");
        schedule = AppBlockSchedule.defaultSchedule();
        await _box.put(_appScheduleKey, schedule);
      } else {
        // Ensure scheduleDays has 7 entries, migrate if old format
        if (schedule.scheduleDays.length != 7) {
            developer.log("Migrating schedule from ${schedule.scheduleDays.length} days to 7 days.", name: "AppBlockScheduleNotifier");
            var newDays = List.generate(7, (i) => schedule!.scheduleDays.firstWhere((d) => d.dayOfWeek == i + 1, orElse: () => BlockScheduleEntry(dayOfWeek: i + 1)));
            schedule.scheduleDays = newDays;
            await schedule.save(); // Save migrated schedule
        }
         developer.log("Loaded schedule from Hive with ${schedule.scheduleDays.length} entries.", name: "AppBlockScheduleNotifier");
      }
      state = AsyncValue.data(schedule);
    } catch (e, s) {
      developer.log("Error loading schedule: $e", name: "AppBlockScheduleNotifier", error: e, stackTrace: s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateScheduleEntry(BlockScheduleEntry entry) async {
    state.whenData((schedule) async {
      final index = schedule.scheduleDays.indexWhere((d) => d.dayOfWeek == entry.dayOfWeek);
      if (index != -1) {
        schedule.scheduleDays[index] = entry;
        try {
          await schedule.save(); // Save the parent AppBlockSchedule object
          state = AsyncValue.data(AppBlockSchedule(scheduleDays: List.from(schedule.scheduleDays))); // Create new instance for state change
          developer.log("Updated schedule entry for day ${entry.dayOfWeek}", name: "AppBlockScheduleNotifier");
        } catch (e,s) {
          developer.log("Error saving schedule entry: $e", name: "AppBlockScheduleNotifier", error: e, stackTrace: s);
          // Optionally revert state or set error state
        }
      }
    });
  }

  Future<void> toggleDayEnable(int dayOfWeek, bool isEnabled) async {
     state.whenData((schedule) async {
      final entry = schedule.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek, orElse: () => BlockScheduleEntry(dayOfWeek: dayOfWeek));
      entry.isEnabled = isEnabled;
      // If disabling, clear times? Or leave them for re-enabling? For now, leave them.
      await updateScheduleEntry(entry);
    });
  }

  Future<void> setDayTime(int dayOfWeek, TimeOfDay? startTime, TimeOfDay? endTime) async {
     state.whenData((schedule) async {
      final entry = schedule.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek, orElse: () => BlockScheduleEntry(dayOfWeek: dayOfWeek));
      entry.startTimeOfDay = startTime;
      entry.endTimeOfDay = endTime;
      await updateScheduleEntry(entry);
    });
  }

  // Expose a way to get a specific day's entry for easier use in UI
  BlockScheduleEntry? getScheduleForDay(int dayOfWeek) {
    return state.asData?.value?.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek);
  }
}

final appBlockScheduleProvider = StateNotifierProvider<AppBlockScheduleNotifier, AsyncValue<AppBlockSchedule>>((ref) {
  final box = Hive.box<AppBlockSchedule>(blockScheduleBoxName);
  return AppBlockScheduleNotifier(box);
});
