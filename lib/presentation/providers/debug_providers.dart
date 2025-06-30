import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_time/services/platform_channels/usage_stats_channel.dart';
import 'dart:developer' as developer;

// State for usage stats
class UsageStatsDebugState {
  final bool isLoading;
  final Map<String, Duration>? stats;
  final String? error;

  UsageStatsDebugState({this.isLoading = false, this.stats, this.error});

  UsageStatsDebugState copyWith({
    bool? isLoading,
    Map<String, Duration>? stats,
    String? error,
    bool clearError = false,
    bool clearStats = false,
  }) {
    return UsageStatsDebugState(
      isLoading: isLoading ?? this.isLoading,
      stats: clearStats ? null : (stats ?? this.stats),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// StateNotifier for usage stats
class UsageStatsDebugNotifier extends StateNotifier<UsageStatsDebugState> {
  UsageStatsDebugNotifier() : super(UsageStatsDebugState());

  Future<void> fetchDailyStats() async {
    state = state.copyWith(isLoading: true, clearError: true, clearStats: true);
    try {
      final fetchedStats = await UsageStatsChannel.getAppUsageDurations(intervalType: "daily");
      developer.log("Fetched ${fetchedStats.length} daily stats entries for debug.", name: "UsageStatsDebugNotifier");
      state = state.copyWith(isLoading: false, stats: fetchedStats);
    } catch (e, s) {
      final errorMsg = "Error fetching daily usage stats: $e";
      developer.log(errorMsg, name: "UsageStatsDebugNotifier", error: e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: errorMsg);
    }
  }
}

// Provider for the notifier
final usageStatsDebugProvider = StateNotifierProvider<UsageStatsDebugNotifier, UsageStatsDebugState>((ref) {
  return UsageStatsDebugNotifier();
});
