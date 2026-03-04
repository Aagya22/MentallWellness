import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentalwellness/core/error/failures.dart';
import 'package:mentalwellness/features/journal/domain/usecases/clear_journal_passcode_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/create_journal_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/delete_journal_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/get_journal_passcode_status_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/get_journals_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/set_journal_passcode_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/update_journal_usecase.dart';
import 'package:mentalwellness/features/journal/domain/usecases/verify_journal_passcode_usecase.dart';
import 'package:mentalwellness/features/journal/presentation/state/journal_state.dart';

final journalViewModelProvider =
    NotifierProvider<JournalViewModel, JournalState>(JournalViewModel.new);

class JournalViewModel extends Notifier<JournalState> {
  late final GetJournalsUsecase _get;
  late final CreateJournalUsecase _create;
  late final UpdateJournalUsecase _update;
  late final DeleteJournalUsecase _delete;
  late final GetJournalPasscodeStatusUsecase _passcodeStatus;
  late final SetJournalPasscodeUsecase _passcodeSet;
  late final ClearJournalPasscodeUsecase _passcodeClear;
  late final VerifyJournalPasscodeUsecase _passcodeVerify;

  String? _lastQuery;

  static const String _codePasscodeRequired = 'JOURNAL_PASSCODE_REQUIRED';
  static const String _codePasscodeInvalid = 'JOURNAL_PASSCODE_INVALID';

  @override
  JournalState build() {
    _get = ref.read(getJournalsUsecaseProvider);
    _create = ref.read(createJournalUsecaseProvider);
    _update = ref.read(updateJournalUsecaseProvider);
    _delete = ref.read(deleteJournalUsecaseProvider);
    _passcodeStatus = ref.read(getJournalPasscodeStatusUsecaseProvider);
    _passcodeSet = ref.read(setJournalPasscodeUsecaseProvider);
    _passcodeClear = ref.read(clearJournalPasscodeUsecaseProvider);
    _passcodeVerify = ref.read(verifyJournalPasscodeUsecaseProvider);
    return const JournalState();
  }

  bool _isJournalLockedFailure(Failure f) {
    if (f is! ApiFailure) return false;
    if (f.statusCode != 403) return false;
    return f.code == _codePasscodeRequired || f.code == _codePasscodeInvalid;
  }

  void dismissPasscodePrompt() {
    if (state.passcodeRequired != true) return;
    state = state.copyWith(passcodeRequired: false);
  }

  Future<String?> unlockJournal({required String passcode}) async {
    final cleaned = passcode.trim();
    final res = await _passcodeVerify(passcode: cleaned);
    return await res.fold((f) async => f.message, (_) async {
      state = state.copyWith(passcodeRequired: false, errorMessage: null);
      return null;
    });
  }

  Future<bool?> getJournalPasscodeStatus() async {
    final res = await _passcodeStatus();
    return res.fold((_) => null, (enabled) => enabled);
  }

  Future<String?> enableJournalPasscode({
    required String passcode,
    required String password,
  }) async {
    final res = await _passcodeSet(
      passcode: passcode.trim(),
      password: password,
    );
    return res.fold((f) => f.message, (_) => null);
  }

  Future<String?> disableJournalPasscode({required String password}) async {
    final res = await _passcodeClear(password: password);
    return await res.fold((f) async => f.message, (_) async {
      state = state.copyWith(passcodeRequired: false, errorMessage: null);
      await fetchJournals(q: _lastQuery);
      return null;
    });
  }

  Future<void> fetchJournals({String? q}) async {
    _lastQuery = q;
    state = state.copyWith(status: JournalStatus.loading, errorMessage: null);
    final res = await _get(q: q);
    res.fold(
      (f) {
        if (_isJournalLockedFailure(f)) {
          state = state.copyWith(
            status: JournalStatus.initial,
            journals: const [],
            errorMessage: null,
            passcodeRequired: true,
          );
          return;
        }
        state = state.copyWith(
          status: JournalStatus.error,
          errorMessage: f.message,
          passcodeRequired: false,
        );
      },
      (list) => state = state.copyWith(
        status: JournalStatus.loaded,
        journals: list,
        passcodeRequired: false,
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
        if (_isJournalLockedFailure(f)) {
          state = state.copyWith(
            status: JournalStatus.initial,
            journals: const [],
            errorMessage: null,
            passcodeRequired: true,
          );
          return false;
        }
        state = state.copyWith(
          status: JournalStatus.error,
          errorMessage: f.message,
          passcodeRequired: false,
        );
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
    final res = await _update(
      id: id,
      title: title,
      content: content,
      date: date,
    );
    return res.fold(
      (f) {
        if (_isJournalLockedFailure(f)) {
          state = state.copyWith(
            status: JournalStatus.initial,
            journals: const [],
            errorMessage: null,
            passcodeRequired: true,
          );
          return false;
        }
        state = state.copyWith(
          status: JournalStatus.error,
          errorMessage: f.message,
          passcodeRequired: false,
        );
        return false;
      },
      (updated) {
        final next =
            state.journals.map((j) => j.id == updated.id ? updated : j).toList()
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
        if (_isJournalLockedFailure(f)) {
          state = state.copyWith(
            status: JournalStatus.initial,
            journals: const [],
            errorMessage: null,
            passcodeRequired: true,
          );
          return false;
        }
        state = state.copyWith(
          status: JournalStatus.error,
          errorMessage: f.message,
          passcodeRequired: false,
        );
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