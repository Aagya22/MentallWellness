import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/reminder/domain/entities/reminder_entity.dart';

enum ReminderStatus { initial, loading, loaded, saving, error }

class ReminderState extends Equatable {
  final ReminderStatus status;
  final List<ReminderEntity> reminders;
  final String? errorMessage;

  const ReminderState({
    this.status = ReminderStatus.initial,
    this.reminders = const [],
    this.errorMessage,
  });

  ReminderState copyWith({
    ReminderStatus? status,
    List<ReminderEntity>? reminders,
    String? errorMessage,
  }) {
    return ReminderState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, reminders, errorMessage];
}
