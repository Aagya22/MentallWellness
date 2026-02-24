import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/exercise/domain/usecases/create_exercise_usecase.dart';
import 'package:mentalwellness/features/exercise/domain/usecases/get_exercises_usecase.dart';
import 'package:mentalwellness/features/exercise/domain/usecases/complete_guided_exercise_usecase.dart';
import 'package:mentalwellness/features/exercise/presentation/state/exercise_state.dart';
import 'package:mentalwellness/features/exercise/domain/usecases/get_guided_history_usecase.dart';

final exerciseViewModelProvider = NotifierProvider<ExerciseViewModel, ExerciseState>(
  ExerciseViewModel.new,
);

class ExerciseViewModel extends Notifier<ExerciseState> {
  late final GetExercisesUsecase _get;
  late final CreateExerciseUsecase _create;
  late final CompleteGuidedExerciseUsecase _completeGuided;
  late final GetGuidedHistoryUsecase _getGuidedHistory;

  @override
  ExerciseState build() {
    _get = ref.read(getExercisesUsecaseProvider);
    _create = ref.read(createExerciseUsecaseProvider);
    _completeGuided = ref.read(completeGuidedExerciseUsecaseProvider);
    _getGuidedHistory = ref.read(getGuidedHistoryUsecaseProvider);

    Future.microtask(refresh);
    return const ExerciseState();
  }

  Future<void> refresh() async {
    state = state.copyWith(status: ExerciseStatus.loading, errorMessage: null);
    final res = await _get();
    res.fold(
      (f) => state = state.copyWith(
        status: ExerciseStatus.error,
        errorMessage: f.message,
      ),
      (list) => state = state.copyWith(
        status: ExerciseStatus.loaded,
        exercises: list,
      ),
    );
  }

  Future<bool> completeGuidedExercise({
    required String title,
    required String category,
    required int plannedDurationSeconds,
    required int elapsedSeconds,
    DateTime? completedAt,
  }) async {
    state = state.copyWith(errorMessage: null);
    final res = await _completeGuided(
      title: title,
      category: category,
      plannedDurationSeconds: plannedDurationSeconds,
      elapsedSeconds: elapsedSeconds,
      completedAt: completedAt,
    );

    Failure? failure;
    res.fold(
      (f) => failure = f,
      (_) {},
    );

    if (failure != null) {
      state = state.copyWith(status: ExerciseStatus.error, errorMessage: failure!.message);
      return false;
    }

    await refresh();
    return true;
  }

  Future<void> getGuidedHistory({
    DateTime? from,
    DateTime? to,
  }) async {
    state = state.copyWith(isGuidedHistoryLoading: true, errorMessage: null);
    final res = await _getGuidedHistory(from: from, to: to);
    state = state.copyWith(isGuidedHistoryLoading: false);

    res.fold(
      (f) => state = state.copyWith(errorMessage: f.message),
      (history) => state = state.copyWith(guidedHistory: history),
    );
  }

  Future<bool> createExercise({
    required String type,
    required int duration,
    DateTime? date,
    String? notes,
  }) async {
    state = state.copyWith(status: ExerciseStatus.saving, errorMessage: null);
    final res = await _create(
      type: type,
      duration: duration,
      date: date,
      notes: notes,
    );

    return res.fold(
      (f) {
        state = state.copyWith(status: ExerciseStatus.error, errorMessage: f.message);
        return false;
      },
      (created) {
        final next = [created, ...state.exercises]
          ..sort((a, b) => b.date.compareTo(a.date));
        state = state.copyWith(status: ExerciseStatus.loaded, exercises: next);
        return true;
      },
    );
  }
}
