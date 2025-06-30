import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:task_time/core/theme/app_theme.dart';
import 'package:task_time/domain/entities/task_entity.dart';
import 'package:task_time/presentation/pages/dashboard/dashboard_page.dart';
import 'package:task_time/presentation/pages/settings/settings_page.dart';
import 'package:task_time/presentation/pages/settings/block_schedule_page.dart';
import 'package:task_time/presentation/pages/settings/manage_blocked_list_page.dart'; // Import new page
import 'package:task_time/presentation/pages/splash/splash_page.dart';
import 'package:task_time/presentation/pages/task_form/task_form_page.dart';

// TODO: Define actual routes
final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      name: 'task_form', // Optional: name for easier navigation
      path: '/task-form',
      builder: (context, state) {
        final TaskEntity? task = state.extra as TaskEntity?; // Pass task for editing
        return TaskFormPage(task: task);
      },
    ),
    GoRoute(
      name: 'block_schedule',
      path: '/settings/block-schedule',
      builder: (context, state) => const BlockSchedulePage(),
    ),
    GoRoute(
      name: 'manage_blocked_list',
      path: '/settings/manage-blocked-list',
      builder: (context, state) => const ManageBlockedListPage(),
    ),
  ],
);

class TaskTimeApp extends StatelessWidget {
  const TaskTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TaskTime',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark mode as per spec
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
