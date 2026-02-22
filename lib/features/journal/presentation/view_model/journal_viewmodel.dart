import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/features/journal/domain/usecases/create_journal_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/delete_journal_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/get_journals_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/update_journal_usecase.dart';
import 'package:mentalwellness/features/journal/presentation/state/journal_state.dart';

final journalViewModelProvider = NotifierProvider<JournalViewModel, JournalState>(
  JournalViewModel.new,
);

class JournalViewModel extends Notifier<JournalState> {
  late final GetJournalsUsecase _get;
  late final CreateJournalUsecase _create;
  late final UpdateJournalUsecase _update;
  late final DeleteJournalUsecase _delete;

  @override
  JournalState build() {
    _get = ref.read(getJournalsUsecaseProvider);
    _create = ref.read(createJournalUsecaseProvider);
    _update = ref.read(updateJournalUsecaseProvider);
    _delete = ref.read(deleteJournalUsecaseProvider);

    Future.microtask(fetchJournals);
    return const JournalState();
  }

  Future<void> fetchJournals({String? q}) async {
    state = state.copyWith(status: JournalStatus.loading, errorMessage: null);
    final res = await _get(q: q);
    res.fold(
      (f) => state = state.copyWith(
        status: JournalStatus.error,
        errorMessage: f.message,
      ),
      (list) => state = state.copyWith(
        status: JournalStatus.loaded,
        journals: list,
      ),
    );
  }

  Future<bool> createEntry({
    required String title,
    required String content,
    DateTime? date,
  }) async {
    state = state.copyWith(status: JournalStatus.saving, errorMessage: null);
    final res = await _create(title: title, content: content, date: date);
    return res.fold(
      (f) {
        state = state.copyWith(status: JournalStatus.error, errorMessage: f.message);
        return false;
      },
      (created) {
        final next = [created, ...state.journals]
          ..sort((a, b) => b.date.compareTo(a.date));
        state = state.copyWith(status: JournalStatus.loaded, journals: next);
        return true;
      },
    );
  }

  Future<bool> updateEntry({
    required String id,
    String? title,
    String? content,
    DateTime? date,
  }) async {
    state = state.copyWith(status: JournalStatus.saving, errorMessage: null);
    final res = await _update(id: id, title: title, content: content, date: date);
    return res.fold(
      (f) {
        state = state.copyWith(status: JournalStatus.error, errorMessage: f.message);
        return false;
      },
      (updated) {
        final next = state.journals
            .map((j) => j.id == updated.id ? updated : j)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        state = state.copyWith(status: JournalStatus.loaded, journals: next);
        return true;
      },
    );
  }

  Future<bool> deleteEntry({required String id}) async {
    state = state.copyWith(status: JournalStatus.saving, errorMessage: null);
    final res = await _delete(id: id);
    return res.fold(
      (f) {
        state = state.copyWith(status: JournalStatus.error, errorMessage: f.message);
        return false;
      },
      (_) {
        final next = state.journals.where((j) => j.id != id).toList();
        state = state.copyWith(status: JournalStatus.loaded, journals: next);
        return true;
      },
    );
  }
}
