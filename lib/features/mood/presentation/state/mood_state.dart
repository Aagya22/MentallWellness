import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_entity.dart';
import 'package:mentalwellness/features/mood/domain/entities/mood_overview_entity.dart';

enum MoodStatus { initial, loading, loaded, saving, error }

class MoodState extends Equatable {
  final MoodStatus status;
  final MoodOverviewEntity? overview;
  final List<MoodEntity> moods;
  final String? errorMessage;

  const MoodState({
    this.status = MoodStatus.initial,
    this.overview,
    this.moods = const [],
    this.errorMessage,
  });

  MoodState copyWith({
    MoodStatus? status,
    MoodOverviewEntity? overview,
    List<MoodEntity>? moods,
    String? errorMessage,
  }) {
    return MoodState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      moods: moods ?? this.moods,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, overview, moods, errorMessage];
}
