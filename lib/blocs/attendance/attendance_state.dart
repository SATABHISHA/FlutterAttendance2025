import 'package:equatable/equatable.dart';
import '../../models/attendance_model.dart';

enum AttendanceStateStatus { initial, loading, loaded, error }

class AttendanceState extends Equatable {
  final AttendanceStateStatus status;
  final AttendanceModel? todayAttendance;
  final List<AttendanceModel> attendanceHistory;
  final List<AttendanceModel> subordinatesAttendance;
  final String? errorMessage;
  final bool isCheckingIn;
  final bool isCheckingOut;

  const AttendanceState({
    this.status = AttendanceStateStatus.initial,
    this.todayAttendance,
    this.attendanceHistory = const [],
    this.subordinatesAttendance = const [],
    this.errorMessage,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
  });

  bool get hasCheckedIn => todayAttendance?.hasCheckedIn ?? false;
  bool get hasCheckedOut => todayAttendance?.hasCheckedOut ?? false;
  bool get canCheckOut => hasCheckedIn && !hasCheckedOut;

  AttendanceState copyWith({
    AttendanceStateStatus? status,
    AttendanceModel? todayAttendance,
    List<AttendanceModel>? attendanceHistory,
    List<AttendanceModel>? subordinatesAttendance,
    String? errorMessage,
    bool? isCheckingIn,
    bool? isCheckingOut,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      attendanceHistory: attendanceHistory ?? this.attendanceHistory,
      subordinatesAttendance: subordinatesAttendance ?? this.subordinatesAttendance,
      errorMessage: errorMessage ?? this.errorMessage,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
    );
  }

  @override
  List<Object?> get props => [
        status,
        todayAttendance,
        attendanceHistory,
        subordinatesAttendance,
        errorMessage,
        isCheckingIn,
        isCheckingOut,
      ];
}
