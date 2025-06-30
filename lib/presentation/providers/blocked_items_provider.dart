import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:task_time/domain/entities/blocked_item_entity.dart';
import 'package:task_time/main.dart'; // For blockedItemsBoxName
import 'dart:developer' as developer;
import 'package:device_apps/device_apps.dart'; // To get list of installed apps

const String _blockedListKey = 'main_blocked_items_list';

class BlockedItemsNotifier extends StateNotifier<AsyncValue<BlockedItemsList>> {
  final Box<BlockedItemsList> _box;

  BlockedItemsNotifier(this._box) : super(const AsyncValue.loading()) {
    _loadBlockedItems();
  }

  Future<void> _loadBlockedItems() async {
    try {
      state = const AsyncValue.loading();
      BlockedItemsList? items = _box.get(_blockedListKey);
      if (items == null) {
        developer.log("No blocked items list found, creating empty list.", name: "BlockedItemsNotifier");
        items = BlockedItemsList.empty();
        await _box.put(_blockedListKey, items);
      }
      state = AsyncValue.data(items);
    } catch (e, s) {
      developer.log("Error loading blocked items: $e", name: "BlockedItemsNotifier", error: e, stackTrace: s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addBlockedApp(Application app) async {
    state.whenData((currentList) async {
      final newApp = BlockedAppEntity(packageName: app.packageName, appName: app.appName);
      if (!currentList.apps.any((a) => a.packageName == newApp.packageName)) {
        currentList.apps.add(newApp);
        try {
          await currentList.save();
          state = AsyncValue.data(BlockedItemsList(apps: List.from(currentList.apps), websites: currentList.websites));
           developer.log("Added app to blocklist: ${newApp.packageName}", name: "BlockedItemsNotifier");
        } catch (e,s) {
          developer.log("Error saving blocked app: $e", name: "BlockedItemsNotifier", error: e, stackTrace: s);
        }
      }
    });
  }

  Future<void> removeBlockedApp(String packageName) async {
    state.whenData((currentList) async {
      currentList.apps.removeWhere((app) => app.packageName == packageName);
      try {
        await currentList.save();
        state = AsyncValue.data(BlockedItemsList(apps: List.from(currentList.apps), websites: currentList.websites));
        developer.log("Removed app from blocklist: $packageName", name: "BlockedItemsNotifier");
      } catch (e,s) {
          developer.log("Error removing blocked app: $e", name: "BlockedItemsNotifier", error: e, stackTrace: s);
      }
    });
  }

  Future<void> addBlockedWebsite(String url) async {
    // Basic URL normalization (more robust parsing might be needed)
    final normalizedUrl = Uri.parse(url.startsWith('http') ? url : 'http://$url').host;
    if (normalizedUrl.isEmpty) {
      developer.log("Attempted to add empty or invalid URL.", name: "BlockedItemsNotifier");
      return; // Or throw error
    }

    state.whenData((currentList) async {
      final newSite = BlockedWebsiteEntity(url: normalizedUrl);
      if (!currentList.websites.any((w) => w.url == newSite.url)) {
        currentList.websites.add(newSite);
        try {
          await currentList.save();
          state = AsyncValue.data(BlockedItemsList(apps: currentList.apps, websites: List.from(currentList.websites)));
          developer.log("Added website to blocklist: $normalizedUrl", name: "BlockedItemsNotifier");
        } catch (e,s) {
           developer.log("Error saving blocked website: $e", name: "BlockedItemsNotifier", error: e, stackTrace: s);
        }
      }
    });
  }

  Future<void> removeBlockedWebsite(String url) async {
    state.whenData((currentList) async {
      currentList.websites.removeWhere((site) => site.url == url);
      try {
        await currentList.save();
        state = AsyncValue.data(BlockedItemsList(apps: currentList.apps, websites: List.from(currentList.websites)));
        developer.log("Removed website from blocklist: $url", name: "BlockedItemsNotifier");
      } catch (e,s) {
        developer.log("Error removing blocked website: $e", name: "BlockedItemsNotifier", error: e, stackTrace: s);
      }
    });
  }

  bool isAppBlocked(String packageName) {
    return state.asData?.value?.apps.any((app) => app.packageName == packageName) ?? false;
  }

  bool isWebsiteBlocked(String url) {
    // Normalize URL for checking (e.g., just the host)
    try {
      final host = Uri.parse(url.startsWith('http') ? url : 'http://$url').host;
      if (host.isEmpty) return false;
      return state.asData?.value?.websites.any((site) => site.url == host) ?? false;
    } catch (_) {
      return false; // Invalid URL
    }
  }
}

final blockedItemsProvider = StateNotifierProvider<BlockedItemsNotifier, AsyncValue<BlockedItemsList>>((ref) {
  final box = Hive.box<BlockedItemsList>(blockedItemsBoxName);
  return BlockedItemsNotifier(box);
});


// Provider to get the list of installed applications (excluding system apps)
// This uses the device_apps package.
final installedAppsProvider = FutureProvider<List<Application>>((ref) async {
  // includeAppIcons: true can be memory intensive if there are many apps.
  // includeSystemApps: false is usually what we want.
  return await DeviceApps.getInstalledApplications(
    includeAppIcons: true, // Set to true to get icons
    includeSystemApps: false,
    onlyAppsWithLaunchIntent: true // Usually better to only show launchable apps
  );
});
