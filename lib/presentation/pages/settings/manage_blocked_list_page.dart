import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/domain/entities/blocked_item_entity.dart';
import 'package:task_time/presentation/providers/blocked_items_provider.dart';
import 'package:device_apps/device_apps.dart'; // For app icons if ApplicationWithIcon is used
import 'dart:developer' as developer;


class ManageBlockedListPage extends ConsumerWidget {
  const ManageBlockedListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Blocked List'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Applications', icon: Icon(Icons.apps)),
              Tab(text: 'Websites', icon: Icon(Icons.public)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BlockedAppsTab(),
            _BlockedWebsitesTab(),
          ],
        ),
      ),
    );
  }
}

class _BlockedAppsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installedAppsAsync = ref.watch(installedAppsProvider);
    final blockedItemsState = ref.watch(blockedItemsProvider);

    return installedAppsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return const Center(child: Text('No non-system applications found.'));
        }
        return blockedItemsState.when(
          data: (blockedList) {
            return ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                final isBlocked = blockedList.apps.any((bApp) => bApp.packageName == app.packageName);

                ImageProvider? iconImageProvider;
                if (app is ApplicationWithIcon && app.icon.isNotEmpty) {
                    iconImageProvider = MemoryImage(app.icon);
                }


                return CheckboxListTile(
                  title: Text(app.appName),
                  subtitle: Text(app.packageName, style: Theme.of(context).textTheme.bodySmall),
                  secondary: iconImageProvider != null
                    ? CircleAvatar(backgroundImage: iconImageProvider, backgroundColor: Colors.transparent)
                    : CircleAvatar(child: Text(app.appName.substring(0,1))),
                  value: isBlocked,
                  onChanged: (bool? value) {
                    if (value == true) {
                      ref.read(blockedItemsProvider.notifier).addBlockedApp(app);
                    } else {
                      ref.read(blockedItemsProvider.notifier).removeBlockedApp(app.packageName);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading blocked list: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading installed apps: $err')),
    );
  }
}

class _BlockedWebsitesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BlockedWebsitesTab> createState() => _BlockedWebsitesTabState();
}

class _BlockedWebsitesTabState extends ConsumerState<_BlockedWebsitesTab> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _addWebsite() {
    if (_formKey.currentState!.validate()) {
      final url = _urlController.text.trim();
      developer.log("Attempting to add website: $url", name: "_BlockedWebsitesTab");
      try {
        // Basic validation: try to parse as URI, get host
        final host = Uri.parse(url.startsWith('http') ? url : 'http://$url').host;
        if (host != null && host.isNotEmpty) {
            ref.read(blockedItemsProvider.notifier).addBlockedWebsite(host);
            _urlController.clear();
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid URL format. Please enter a valid domain (e.g., example.com)'))
            );
        }
      } catch (e) {
         developer.log("Error parsing URL: $e", name: "_BlockedWebsitesTab");
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid URL format.'))
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedItemsState = ref.watch(blockedItemsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Website URL (e.g., example.com)',
                      hintText: 'youtube.com',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a website URL';
                      }
                      try {
                        final host = Uri.parse(value.trim().startsWith('http') ? value.trim() : 'http://${value.trim()}').host;
                        if (host == null || host.isEmpty || !host.contains('.')) {
                           return 'Invalid URL format';
                        }
                      } catch (_) {
                        return 'Invalid URL format';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addWebsite,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: blockedItemsState.when(
            data: (blockedList) {
              if (blockedList.websites.isEmpty) {
                return const Center(child: Text('No websites added to the block list yet.'));
              }
              return ListView.builder(
                itemCount: blockedList.websites.length,
                itemBuilder: (context, index) {
                  final website = blockedList.websites[index];
                  return ListTile(
                    title: Text(website.url),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        ref.read(blockedItemsProvider.notifier).removeBlockedWebsite(website.url);
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading blocked websites: $err')),
          ),
        ),
      ],
    );
  }
   @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
