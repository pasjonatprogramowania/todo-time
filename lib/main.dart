import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_time/app.dart';
import 'package:task_time/data/models/task_model.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/domain/entities/block_schedule_entity.dart';
import 'package:task_time/domain/entities/blocked_item_entity.dart'; // Import new blocked item entities

const String tasksBoxName = 'tasks';
const String blockScheduleBoxName = 'block_schedule';
const String blockedItemsBoxName = 'blocked_items';
// const String settingsBoxName = 'settings';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(TaskCategoryAdapter());
  Hive.registerAdapter(BlockScheduleEntryAdapter()); // Generated
  Hive.registerAdapter(AppBlockScheduleAdapter());   // Generated
  Hive.registerAdapter(BlockedAppEntityAdapter());    // Generated
  Hive.registerAdapter(BlockedWebsiteEntityAdapter());// Generated
  Hive.registerAdapter(BlockedItemsListAdapter());    // Generated


  // Open Hive boxes
  await Hive.openBox<TaskModel>(tasksBoxName);
  await Hive.openBox<AppBlockSchedule>(blockScheduleBoxName);
  await Hive.openBox<BlockedItemsList>(blockedItemsBoxName);
  // await Hive.openBox(settingsBoxName);

  runApp(
    const ProviderScope(
      child: TaskTimeApp(),
    ),
  );
}
