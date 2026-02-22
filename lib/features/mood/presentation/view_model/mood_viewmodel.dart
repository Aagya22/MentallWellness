import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/mood/domain/usecases/create_mood_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_mood_overview_usecase.dart';
import 'package:mentalwellness/features/mood/domain/usecases/get_moods_usecase.dart';
import 'package:mentalwellness/features/mood/presentation/state/mood_state.dart';

final moodViewModelProvider = NotifierProvider<MoodViewModel, MoodState>(
  MoodViewModel.new,
);

class MoodViewModel extends Notifier<MoodState> {
  late final GetMoodOverviewUsecase _getOverview;
  late final GetMoodsUsecase _getMoods;
  late final CreateMoodUsecase _create;

  @override
  MoodState build() {
    _getOverview = ref.read(getMoodOverviewUsecaseProvider);
    _getMoods = ref.read(getMoodsUsecaseProvider);
    _create = ref.read(createMoodUsecaseProvider);

    Future.microtask(refresh);
    return const MoodState();
  }

  Future<void> refresh() async {
    state = state.copyWith(status: MoodStatus.loading, errorMessage: null);

    final overviewRes = await _getOverview();
    final moodsRes = await _getMoods();

    final overview = overviewRes.fold((_) => null, (r) => r);
    final moods = moodsRes.fold((_) => null, (r) => r);

    final error = overviewRes.fold((f) => f.message, (_) => null) ??
        moodsRes.fold((f) => f.message, (_) => null);

    if (error != null || overview == null || moods == null) {
      state = state.copyWith(status: MoodStatus.error, errorMessage: error);
      return;
    }

    state = state.copyWith(status: MoodStatus.loaded, overview: overview, moods: moods);
  }

  Future<bool> logMood({
    required int mood,
    String? moodType,
    String? note,
    DateTime? date,
  }) async {
    state = state.copyWith(status: MoodStatus.saving, errorMessage: null);
    final res = await _create(mood: mood, moodType: moodType, note: note, date: date);
    return res.fold(
      (f) {
        state = state.copyWith(status: MoodStatus.error, errorMessage: f.message);
        return false;
      },
      (_) async {
        await refresh();
        return true;
      },
    );
  }
}
