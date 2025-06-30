import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart'; // For TimeOfDay
import 'package:task_time/domain/entities/block_schedule_entity.dart';
import 'package:task_time/main.dart'; // For blockScheduleBoxName
import 'dart:developer' as developer;

const String _appScheduleKey = 'main_app_block_schedule';

class AppBlockScheduleNotifier extends StateNotifier<AsyncValue<AppBlockSchedule>> {
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
            var currentDaysMap = { for (var d in schedule.scheduleDays) d.dayOfWeek : d };
            var newDays = List.generate(7, (i) => currentDaysMap[i+1] ?? BlockScheduleEntry(dayOfWeek: i + 1, isEnabled: false));
            schedule.scheduleDays = newDays;
            await schedule.save();
        } else {
            // Ensure all entries are valid, e.g. not null if they shouldn't be, or have correct dayOfWeek
            bool needsSave = false;
            for(int i=0; i<7; ++i) {
                if(schedule.scheduleDays[i].dayOfWeek != (i+1)) {
                    // This indicates a deeper issue or data corruption, recreate for safety for now
                    developer.log("Schedule data inconsistency found for day ${i+1}. Re-evaluating.", name: "AppBlockScheduleNotifier");
                    schedule.scheduleDays[i] = BlockScheduleEntry(dayOfWeek: i+1, isEnabled: false);
                    needsSave = true;
                }
            }
            if(needsSave) await schedule.save();
        }
         developer.log("Loaded schedule from Hive with ${schedule.scheduleDays.length} entries.", name: "AppBlockScheduleNotifier");
      }
      state = AsyncValue.data(schedule);
    } catch (e, s) {
      developer.log("Error loading schedule: $e", name: "AppBlockScheduleNotifier", error: e, stackTrace: s);
      // Fallback to default if loading fails catastrophically
      try {
        AppBlockSchedule defaultSchedule = AppBlockSchedule.defaultSchedule();
        await _box.put(_appScheduleKey, defaultSchedule); // Attempt to save a good default
        state = AsyncValue.data(defaultSchedule);
         developer.log("Fell back to default schedule due to error.", name: "AppBlockScheduleNotifier");
      } catch (e2, s2) {
        developer.log("Error saving fallback default schedule: $e2", name: "AppBlockScheduleNotifier", error: e2, stackTrace: s2);
        state = AsyncValue.error(e, s); // Show original error if fallback save fails
      }
    }
  }

  Future<void> updateScheduleEntry(BlockScheduleEntry entry) async {
    final currentData = state.asData?.value;
    if (currentData == null) return; // Not loaded yet or in error state

    final newScheduleDays = List<BlockScheduleEntry>.from(currentData.scheduleDays);
    final index = newScheduleDays.indexWhere((d) => d.dayOfWeek == entry.dayOfWeek);

    if (index != -1) {
      newScheduleDays[index] = entry;
      final updatedAppSchedule = AppBlockSchedule(scheduleDays: newScheduleDays);
      try {
        await _box.put(_appScheduleKey, updatedAppSchedule); // Save the whole AppBlockSchedule object
        state = AsyncValue.data(updatedAppSchedule);
        developer.log("Updated schedule entry for day ${entry.dayOfWeek}", name: "AppBlockScheduleNotifier");
      } catch (e,s) {
        developer.log("Error saving schedule entry: $e", name: "AppBlockScheduleNotifier", error: e, stackTrace: s);
        state = AsyncValue.error(e,s); // Revert to error state or handle appropriately
      }
    }
  }

  Future<void> toggleDayEnable(int dayOfWeek, bool isEnabled) async {
    final currentData = state.asData?.value;
    if (currentData == null) return;

    final entry = currentData.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek,
                  orElse: () => BlockScheduleEntry(dayOfWeek: dayOfWeek)); // Should not happen if initialized correctly

    if (entry.isEnabled == isEnabled) return; // No change

    entry.isEnabled = isEnabled;
    await updateScheduleEntry(entry);
  }

  Future<void> setDayTime(int dayOfWeek, TimeOfDay? startTime, TimeOfDay? endTime) async {
    final currentData = state.asData?.value;
    if (currentData == null) return;

    final entry = currentData.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek,
                  orElse: () => BlockScheduleEntry(dayOfWeek: dayOfWeek));

    entry.startTimeOfDay = startTime;
    entry.endTimeOfDay = endTime;
    await updateScheduleEntry(entry);
  }

  BlockScheduleEntry? getScheduleForDay(int dayOfWeek) {
    return state.asData?.value?.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek, orElse: null);
  }
}

final appBlockScheduleProvider = StateNotifierProvider<AppBlockScheduleNotifier, AsyncValue<AppBlockSchedule>>((ref) {
  final box = Hive.box<AppBlockSchedule>(blockScheduleBoxName);
  return AppBlockScheduleNotifier(box);
});
