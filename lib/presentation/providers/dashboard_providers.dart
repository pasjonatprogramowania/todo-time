import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardTaskView { list, matrix }

final dashboardTaskViewProvider = StateProvider<DashboardTaskView>((ref) {
  return DashboardTaskView.list; // Default to list view
});
