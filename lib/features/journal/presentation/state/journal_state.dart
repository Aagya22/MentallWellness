import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/journal/domain/entities/journal_entity.dart';

enum JournalStatus { initial, loading, loaded, saving, error }

class JournalState extends Equatable {
  final JournalStatus status;
  final List<JournalEntity> journals;
  final String? errorMessage;
  final bool passcodeRequired;

  const JournalState({
    this.status = JournalStatus.initial,
    this.journals = const [],
    this.errorMessage,
    this.passcodeRequired = false,
  });

  JournalState copyWith({
    JournalStatus? status,
    List<JournalEntity>? journals,
    String? errorMessage,
    bool? passcodeRequired,
  }) {
    return JournalState(
      status: status ?? this.status,
      journals: journals ?? this.journals,
      errorMessage: errorMessage,
      passcodeRequired: passcodeRequired ?? (this.passcodeRequired == true),
    );
  }

  @override
  List<Object?> get props => [status, journals, errorMessage, passcodeRequired];
}
