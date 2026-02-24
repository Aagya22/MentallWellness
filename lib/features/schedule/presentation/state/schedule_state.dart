import 'package:equatable/equatable.dart';
import 'package:mentalwellness/features/schedule/domain/entities/schedule_entity.dart';

enum ScheduleStatus { initial, loading, loaded, saving, error }

class ScheduleState extends Equatable {
  final ScheduleStatus status;
  final List<ScheduleEntity> schedules;
  final String? errorMessage;
  final String? rangeFrom;
  final String? rangeTo;

  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.schedules = const [],
    this.errorMessage,
    this.rangeFrom,
    this.rangeTo,
  });

  ScheduleState copyWith({
    ScheduleStatus? status,
    List<ScheduleEntity>? schedules,
    String? errorMessage,
    String? rangeFrom,
    String? rangeTo,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      schedules: schedules ?? this.schedules,
      errorMessage: errorMessage,
      rangeFrom: rangeFrom ?? this.rangeFrom,
      rangeTo: rangeTo ?? this.rangeTo,
    );
  }

  @override
  List<Object?> get props => [status, schedules, errorMessage, rangeFrom, rangeTo];
}
