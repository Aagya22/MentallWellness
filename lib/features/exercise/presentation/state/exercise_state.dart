import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/exercise/domain/entities/exercise_entity.dart';
import 'package:mentalwellness/features/exercise/domain/entities/guided_history_entity.dart';

enum ExerciseStatus { initial, loading, loaded, saving, error }

class ExerciseState extends Equatable {
  final ExerciseStatus status;
  final List<ExerciseEntity> exercises;
  final bool isGuidedHistoryLoading;
  final List<GuidedHistoryDayEntity> guidedHistory;
  final String? errorMessage;

  const ExerciseState({
    this.status = ExerciseStatus.initial,
    this.exercises = const [],
    this.isGuidedHistoryLoading = false,
    this.guidedHistory = const [],
    this.errorMessage,
  });

  ExerciseState copyWith({
    ExerciseStatus? status,
    List<ExerciseEntity>? exercises,
    bool? isGuidedHistoryLoading,
    List<GuidedHistoryDayEntity>? guidedHistory,
    String? errorMessage,
  }) {
    return ExerciseState(
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      isGuidedHistoryLoading:
          isGuidedHistoryLoading ?? this.isGuidedHistoryLoading,
      guidedHistory: guidedHistory ?? this.guidedHistory,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        exercises,
        isGuidedHistoryLoading,
        guidedHistory,
        errorMessage,
      ];
}
