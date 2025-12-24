import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class AttendanceLoadToday extends AttendanceEvent {
  final String oderId;

  const AttendanceLoadToday({required this.oderId});

  @override
  List<Object?> get props => [oderId];
}

class AttendanceCheckIn extends AttendanceEvent {
  final String oderId;
  final String userName;
  final String companyId;
  final String corpId;

  const AttendanceCheckIn({
    required this.oderId,
    required this.userName,
    required this.companyId,
    required this.corpId,
  });

  @override
  List<Object?> get props => [oderId, userName, companyId, corpId];
}

class AttendanceCheckOut extends AttendanceEvent {
  final String attendanceId;
  final String userId;

  const AttendanceCheckOut({
    required this.attendanceId,
    required this.userId,
  });

  @override
  List<Object?> get props => [attendanceId, userId];
}

class AttendanceLoadHistory extends AttendanceEvent {
  final String oderId;
  final int limit;

  const AttendanceLoadHistory({
    required this.oderId,
    this.limit = 30,
  });

  @override
  List<Object?> get props => [oderId, limit];
}

class AttendanceLoadSubordinates extends AttendanceEvent {
  final String supervisorId;
  final DateTime? date;

  const AttendanceLoadSubordinates({
    required this.supervisorId,
    this.date,
  });

  @override
  List<Object?> get props => [supervisorId, date];
}
