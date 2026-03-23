import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/base/di/dependency_injection.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP TIMER CUBIT
//
// Manages a countdown timer that pauses the audio player when it expires.
//
// Usage:
//   context.read<SleepTimerCubit>().start(const Duration(minutes: 30));
//   context.read<SleepTimerCubit>().cancel();
//
// Architecture notes:
//   • Uses a dart:async Timer.periodic that ticks every second — no stream
//     subscriptions to forget to cancel.
//   • The AudioPlayer is accessed directly via GetIt (same singleton used by
//     AudioPlayerBloc) — no cross-bloc coupling needed.
//   • Timer is always cancelled in cancel() and close() so there are no leaks.
//   • State is immutable (Equatable) so BlocBuilder rebuilds correctly.
// ─────────────────────────────────────────────────────────────────────────────

// ── STATE ─────────────────────────────────────────────────────────────────────

class SleepTimerState extends Equatable {
  const SleepTimerState({
    required this.isActive,
    required this.remaining,
    required this.selected,
  });

  /// Whether the sleep timer is currently counting down.
  final bool isActive;

  /// Remaining time until the player pauses. Null when inactive.
  final Duration? remaining;

  /// The duration the user most recently selected (shown in UI).
  final Duration? selected;

  /// Convenience: inactive initial state.
  const SleepTimerState.initial()
      : isActive = false,
        remaining = null,
        selected = null;

  SleepTimerState copyWith({
    bool? isActive,
    Duration? remaining,
    Duration? selected,
    bool clearRemaining = false,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remaining: clearRemaining ? null : (remaining ?? this.remaining),
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [isActive, remaining, selected];
}

// ── CUBIT ─────────────────────────────────────────────────────────────────────

class SleepTimerCubit extends Cubit<SleepTimerState> {
  SleepTimerCubit() : super(const SleepTimerState.initial());

  // AudioPlayer singleton injected from GetIt — same instance as AudioPlayerBloc.
  final AudioPlayer _audioPlayer = getIt<AudioPlayer>();

  // Internal countdown timer. Always null when not active.
  Timer? _timer;

  // ── PUBLIC API ──────────────────────────────────────────────────────────────

  /// Predefined duration options shown in the sleep timer UI.
  static const List<Duration> presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 20),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];

  /// Start (or restart) the sleep timer with [duration].
  /// Cancels any currently running timer before starting a new one.
  void start(Duration duration) {
    // Cancel existing timer to avoid double-firing
    _cancelTimer();

    emit(state.copyWith(
      isActive: true,
      remaining: duration,
      selected: duration,
    ));

    // Tick every second and update remaining time.
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  /// Cancel the sleep timer without pausing audio.
  void cancel() {
    _cancelTimer();
    emit(state.copyWith(
      isActive: false,
      clearRemaining: true,
    ));
  }

  // ── PRIVATE METHODS ─────────────────────────────────────────────────────────

  void _onTick(Timer timer) {
    final Duration? current = state.remaining;
    if (current == null || !state.isActive) {
      _cancelTimer();
      return;
    }

    final Duration next = current - const Duration(seconds: 1);

    if (next.inSeconds <= 0) {
      // Time's up — pause the player and reset state.
      _cancelTimer();
      _audioPlayer.pause();
      emit(state.copyWith(
        isActive: false,
        clearRemaining: true,
      ));
    } else {
      // Emit updated remaining time.
      emit(state.copyWith(remaining: next));
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── LIFECYCLE ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    // Always cancel the timer when the cubit is closed.
    // This prevents the callback from firing after the cubit is disposed.
    _cancelTimer();
    return super.close();
  }
}
