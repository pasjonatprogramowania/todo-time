import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/domain/entities/block_schedule_entity.dart';
import 'package:task_time/presentation/providers/schedule_providers.dart';
import 'dart:developer' as developer;

class BlockSchedulePage extends ConsumerWidget {
  const BlockSchedulePage({super.key});

  String _dayOfWeekToString(int day) {
    switch (day) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return 'Unknown Day';
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    int dayOfWeek,
    TimeOfDay? initialTime,
    bool isStartTime,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final schedule = ref.read(appBlockScheduleProvider).asData?.value;
      if (schedule == null) return;

      final entry = schedule.scheduleDays.firstWhere((d) => d.dayOfWeek == dayOfWeek);
      TimeOfDay? newStartTime = entry.startTimeOfDay;
      TimeOfDay? newEndTime = entry.endTimeOfDay;

      if (isStartTime) {
        newStartTime = pickedTime;
      } else {
        newEndTime = pickedTime;
      }

      // Basic validation: end time should be after start time if both are set
      if (newStartTime != null && newEndTime != null) {
        final startMinutes = newStartTime.hour * 60 + newStartTime.minute;
        final endMinutes = newEndTime.hour * 60 + newEndTime.minute;
        if (endMinutes <= startMinutes) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time.'))
            );
            return; // Don't update if invalid
        }
      }
      developer.log("Setting time for day $dayOfWeek: Start: $newStartTime, End: $newEndTime", name: "BlockSchedulePage");
      await ref.read(appBlockScheduleProvider.notifier).setDayTime(dayOfWeek, newStartTime, newEndTime);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsyncValue = ref.watch(appBlockScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Schedule'),
      ),
      body: scheduleAsyncValue.when(
        data: (appSchedule) {
          if (appSchedule.scheduleDays.isEmpty) {
            // This case should ideally be handled by the notifier creating a default schedule
            return const Center(child: Text("No schedule configured. This is unexpected."));
          }
          return ListView.builder(
            itemCount: appSchedule.scheduleDays.length,
            itemBuilder: (context, index) {
              final dayEntry = appSchedule.scheduleDays[index];
              final String dayName = _dayOfWeekToString(dayEntry.dayOfWeek);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dayName, style: Theme.of(context).textTheme.titleMedium),
                          Switch(
                            value: dayEntry.isEnabled,
                            onChanged: (bool value) {
                              ref.read(appBlockScheduleProvider.notifier).toggleDayEnable(dayEntry.dayOfWeek, value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: dayEntry.isEnabled ? 1.0 : 0.5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _TimePickerTile(
                                label: 'Start Time',
                                time: dayEntry.startTimeOfDay,
                                enabled: dayEntry.isEnabled,
                                onTap: () => _pickTime(context, ref, dayEntry.dayOfWeek, dayEntry.startTimeOfDay, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TimePickerTile(
                                label: 'End Time',
                                time: dayEntry.endTimeOfDay,
                                enabled: dayEntry.isEnabled,
                                onTap: () => _pickTime(context, ref, dayEntry.dayOfWeek, dayEntry.endTimeOfDay, false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading schedule: ${err.toString()}')),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final bool enabled;

  const _TimePickerTile({
    required this.label,
    this.time,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: enabled ? Theme.of(context).dividerColor : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? null : Theme.of(context).disabledColor.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: enabled ? Theme.of(context).hintColor : Theme.of(context).disabledColor)),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? 'Not Set',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).disabledColor),
            ),
          ],
        ),
      ),
    );
  }
}
