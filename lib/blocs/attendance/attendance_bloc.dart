import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/services.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceService _attendanceService;
  final LocationService _locationService;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  AttendanceBloc({
    required AttendanceService attendanceService,
    required LocationService locationService,
  })  : _attendanceService = attendanceService,
        _locationService = locationService,
        super(const AttendanceState()) {
    on<AttendanceLoadToday>(_onLoadToday);
    on<AttendanceCheckIn>(_onCheckIn);
    on<AttendanceCheckOut>(_onCheckOut);
    on<AttendanceLoadHistory>(_onLoadHistory);
    on<AttendanceLoadSubordinates>(_onLoadSubordinates);
  }

  Future<void> _onLoadToday(
    AttendanceLoadToday event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStateStatus.loading));

    try {
      final attendance = await _attendanceService.getTodayAttendance(event.oderId);

      emit(state.copyWith(
        status: AttendanceStateStatus.loaded,
        todayAttendance: attendance,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckIn(
    AttendanceCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isCheckingIn: true));

    try {
      final locationData = await _locationService.getFullLocationData();

      final attendance = await _attendanceService.checkIn(
        oderId: event.oderId,
        userName: event.userName,
        companyId: event.companyId,
        corpId: event.corpId,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        address: locationData.address,
        country: locationData.country,
        timezone: locationData.timezone,
      );

      emit(state.copyWith(
        status: AttendanceStateStatus.loaded,
        todayAttendance: attendance,
        isCheckingIn: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStateStatus.error,
        errorMessage: e.toString(),
        isCheckingIn: false,
      ));
    }
  }

  Future<void> _onCheckOut(
    AttendanceCheckOut event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(isCheckingOut: true));

    try {
      final locationData = await _locationService.getFullLocationData();

      final attendance = await _attendanceService.checkOut(
        userId: event.userId,
        attendanceId: event.attendanceId,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        address: locationData.address,
      );

      emit(state.copyWith(
        status: AttendanceStateStatus.loaded,
        todayAttendance: attendance,
        isCheckingOut: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStateStatus.error,
        errorMessage: e.toString(),
        isCheckingOut: false,
      ));
    }
  }

  Future<void> _onLoadHistory(
    AttendanceLoadHistory event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStateStatus.loading));

    try {
      final history = await _attendanceService.getUserAttendanceHistory(
        event.oderId,
        limit: event.limit,
      );

      emit(state.copyWith(
        status: AttendanceStateStatus.loaded,
        attendanceHistory: history,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AttendanceStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSubordinates(
    AttendanceLoadSubordinates event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStateStatus.loading));

    try {
      // Fetch all users and filter client-side (avoiding Firebase index requirement)
      print('Loading subordinates for supervisor: ${event.supervisorId}');
      final usersSnapshot = await _database.ref('users').get();

      List<Map<String, dynamic>> subordinatesInfo = [];
      if (usersSnapshot.exists) {
        final usersMap = usersSnapshot.value as Map<dynamic, dynamic>;
        print('Total users in database: ${usersMap.length}');
        usersMap.forEach((key, value) {
          final userData = value as Map<dynamic, dynamic>;
          final supervisorId = userData['supervisorId']?.toString();
          if (supervisorId == event.supervisorId) {
            subordinatesInfo.add({
              'id': key.toString(),
              'name': userData['name']?.toString() ?? 'Unknown',
              'companyId': userData['companyId']?.toString() ?? '',
              'corpId': userData['corpId']?.toString() ?? '',
            });
            print('Found subordinate: ${userData['name']}');
          }
        });
      }

      print('Loading attendance for ${subordinatesInfo.length} subordinates');
      final subordinates = await _attendanceService.getSubordinatesAttendanceWithAbsent(
        subordinatesInfo,
        date: event.date,
      );
      print('Loaded ${subordinates.length} attendance records');

      emit(state.copyWith(
        status: AttendanceStateStatus.loaded,
        subordinatesAttendance: subordinates,
      ));
    } catch (e) {
      print('Error loading subordinates: $e');
      emit(state.copyWith(
        status: AttendanceStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
