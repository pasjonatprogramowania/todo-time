import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:task_time/services/platform_channels/background_service_channel.dart';
import 'package:task_time/presentation/providers/task_usecase_providers.dart'; // For ResetTasksStatusUseCase
import 'dart:developer' as developer;

const String _earnedScreenTimeKey = 'earned_screen_time_ms';
const String _screenTimeBoxName = 'screen_time_data';

final earnedScreenTimeRepositoryProvider = Provider((ref) {
  return EarnedScreenTimeRepository(Hive.box<dynamic>(_screenTimeBoxName));
});

class EarnedScreenTimeRepository {
  final Box _box;
  EarnedScreenTimeRepository(this._box);

  Future<void> addScreenTime(Duration duration) async {
    final currentMs = getEarnedScreenTimeMs();
    final newTotalMs = currentMs + duration.inMilliseconds;
    await _box.put(_earnedScreenTimeKey, newTotalMs);
    developer.log("Added ${duration.inMilliseconds}ms. New total earned: $newTotalMs ms", name: "EarnedScreenTimeRepo");
    await BackgroundServiceChannel.updateScreenTime(milliseconds: newTotalMs);
  }

  Future<void> setScreenTimeMs(int milliseconds) async {
    await _box.put(_earnedScreenTimeKey, milliseconds);
    developer.log("Set screen time to $milliseconds ms in Hive.", name: "EarnedScreenTimeRepo");
    // We only call updateScreenTime if Flutter initiated the change.
    // If it's a reset signal from native, native already knows.
    // However, the current call path for reset is native -> stream -> notifier -> this.setScreenTimeMs(0)
    // So, this will call updateScreenTime(0) back to native, which is redundant but harmless.
    await BackgroundServiceChannel.updateScreenTime(milliseconds: milliseconds);
  }

  int getEarnedScreenTimeMs() {
    return _box.get(_earnedScreenTimeKey, defaultValue: 0) as int;
  }
}

class ScreenTimeDisplayNotifier extends StateNotifier<AsyncValue<Duration>> {
  final EarnedScreenTimeRepository _repository;
  final Reader _read; // Riverpod's Reader to access other providers
  StreamSubscription? _nativeStreamSubscription;

  ScreenTimeDisplayNotifier(this._repository, this._read) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    final initialMs = _repository.getEarnedScreenTimeMs();
    state = AsyncValue.data(Duration(milliseconds: initialMs));
    developer.log("ScreenTimeDisplayNotifier initialized with: $initialMs ms from Hive.", name: "ScreenTimeDisplay");

    _nativeStreamSubscription?.cancel();
    _nativeStreamSubscription = BackgroundServiceChannel.screenTimeUpdateStream.listen(
      (milliseconds) {
        if (milliseconds == -1) {
          developer.log("Received daily reset signal from native.", name: "ScreenTimeDisplay");
          // Native service has reset its internal screen time to 0.
          // Flutter side needs to update its Hive storage and reset task statuses.
          _repository.setScreenTimeMs(0).then((_) { // Ensure Hive is updated first
             state = const AsyncValue.data(Duration.zero); // Then update UI state
             developer.log("Screen time set to 0 in Hive by Notifier.", name: "ScreenTimeDisplay");
          });

          try {
            _read(resetTasksStatusUseCaseProvider).call().then((_) {
                 developer.log("Task statuses reset successfully after daily signal.", name: "ScreenTimeDisplay");
            }).catchError((e,s) {
                 developer.log("Error calling ResetTasksStatusUseCase: $e", name: "ScreenTimeDisplay", error:e, stackTrace:s);
            });
          } catch (e,s) {
             developer.log("Synchronous error calling ResetTasksStatusUseCase: $e", name: "ScreenTimeDisplay", error:e, stackTrace:s);
          }

        } else {
          developer.log("Received screen time update from native: $milliseconds ms", name: "ScreenTimeDisplay");
          state = AsyncValue.data(Duration(milliseconds: milliseconds));
          // Potentially update Hive here if native is the absolute source of truth during deduction
          // _repository.setScreenTimeMs(milliseconds); // Be cautious of loops if native also listens to this update.
        }
      },
      onError: (error) {
        developer.log("Error on screen time stream: $error", name: "ScreenTimeDisplay", error: error);
        state = AsyncValue.error(error, StackTrace.current);
      }
    );
  }

  Future<void> refreshFromSource() async {
     final currentMs = _repository.getEarnedScreenTimeMs();
     state = AsyncValue.data(Duration(milliseconds: currentMs));
     await BackgroundServiceChannel.updateScreenTime(milliseconds: currentMs);
     developer.log("Refreshed screen time from source: $currentMs ms.", name: "ScreenTimeDisplay");
  }

  @override
  void dispose() {
    _nativeStreamSubscription?.cancel();
    super.dispose();
  }
}

final screenTimeDisplayProvider = StateNotifierProvider<ScreenTimeDisplayNotifier, AsyncValue<Duration>>((ref) {
  // Pass ref.read to the notifier's constructor for accessing other providers
  return ScreenTimeDisplayNotifier(ref.watch(earnedScreenTimeRepositoryProvider), ref.read);
});

// Extension method for BackgroundServiceChannel to send screen time updates
extension BackgroundServiceScreenTimeExtension on BackgroundServiceChannel {
  static Future<String?> updateScreenTime({required int milliseconds}) async {
     try {
      developer.log('Sending screen time to background service: $milliseconds ms', name: "BackgroundServiceChannelExt");
      final String? result = await BackgroundServiceChannel.platform.invokeMethod('updateScreenTime', {
        'earnedScreenTimeMs': milliseconds,
      });
      developer.log('Update screen time platform channel result: $result', name: "BackgroundServiceChannelExt");
      return result;
    } on PlatformException catch (e) {
      developer.log('Failed to update service screen time: ${e.message}', name: "BackgroundServiceChannelExt", error: e);
      return "Failed: ${e.message}";
    }
  }
}
