import 'package:firebase_database/firebase_database.dart';
import '../models/attendance_model.dart';
import '../models/project_model.dart';
import 'project_service.dart';

class AttendanceService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ProjectService _projectService = ProjectService();

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      final snapshot = await _database
          .ref('attendance/$userId/$dateKey')
          .get();

      if (snapshot.exists) {
        return AttendanceModel.fromRealtimeDB(
          snapshot.key!,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get today\'s attendance: $e');
    }
  }

  /// Check if user can check in from the given location
  /// Returns a map with 'canCheckIn' boolean and 'reason' string
  Future<Map<String, dynamic>> validateCheckInLocation({
    required String userId,
    required double latitude,
    required double longitude,
    required bool canCheckInFromAnywhere,
  }) async {
    try {
      // If user has permission to check in from anywhere, allow it
      if (canCheckInFromAnywhere) {
        return {
          'canCheckIn': true,
          'reason': null,
          'projectAssignment': null,
        };
      }

      // Check if user is within any active project boundary
      final result = await _projectService.canUserCheckIn(userId, latitude, longitude);
      
      if (result['canCheckIn'] == true) {
        return {
          'canCheckIn': true,
          'reason': null,
          'projectAssignment': result['assignment'],
        };
      } else {
        return {
          'canCheckIn': false,
          'reason': result['reason'] ?? 'You are not within any allocated project location',
          'projectAssignment': null,
        };
      }
    } catch (e) {
      // If there's an error checking location, allow check-in but log the error
      print('Error validating check-in location: $e');
      return {
        'canCheckIn': true,
        'reason': null,
        'projectAssignment': null,
      };
    }
  }

  Future<AttendanceModel> checkIn({
    required String oderId,
    required String userName,
    required String companyId,
    required String corpId,
    required double latitude,
    required double longitude,
    required String address,
    String? country,
    String? timezone,
    String? projectId,
    String? projectName,
  }) async {
    try {
      // Check if already checked in today
      final existingAttendance = await getTodayAttendance(oderId);
      if (existingAttendance != null && existingAttendance.hasCheckedIn) {
        throw Exception('Already checked in for today');
      }

      final now = DateTime.now();
      final dateKey = _getDateKey(now);
      
      final attendance = AttendanceModel(
        id: dateKey,
        oderId: oderId,
        userName: userName,
        companyId: companyId,
        corpId: corpId,
        date: DateTime(now.year, now.month, now.day),
        checkInTime: now,
        checkInLatitude: latitude,
        checkInLongitude: longitude,
        checkInAddress: address,
        status: AttendanceStatus.checkedIn,
        country: country,
        timezone: timezone,
        projectId: projectId,
        projectName: projectName,
      );

      await _database
          .ref('attendance/$oderId/$dateKey')
          .set(attendance.toRealtimeDB());

      // Index by project if specified
      if (projectId != null && projectId.isNotEmpty) {
        await _database.ref('project_attendance/$projectId/$dateKey/$oderId').set(true);
      }

      return attendance;
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  /// Check in with location validation
  Future<AttendanceModel> checkInWithValidation({
    required String oderId,
    required String userName,
    required String companyId,
    required String corpId,
    required double latitude,
    required double longitude,
    required String address,
    required bool canCheckInFromAnywhere,
    String? country,
    String? timezone,
  }) async {
    // Validate location first
    final validation = await validateCheckInLocation(
      userId: oderId,
      latitude: latitude,
      longitude: longitude,
      canCheckInFromAnywhere: canCheckInFromAnywhere,
    );

    if (validation['canCheckIn'] != true) {
      throw Exception(validation['reason'] ?? 'Cannot check in from this location');
    }

    // Get project info from assignment if available
    String? projectId;
    String? projectName;
    
    if (validation['projectAssignment'] != null) {
      final assignment = validation['projectAssignment'] as ProjectAssignment;
      projectId = assignment.projectId;
      projectName = assignment.projectName;
    }

    return checkIn(
      oderId: oderId,
      userName: userName,
      companyId: companyId,
      corpId: corpId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      country: country,
      timezone: timezone,
      projectId: projectId,
      projectName: projectName,
    );
  }

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required String userId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      final snapshot = await _database
          .ref('attendance/$userId/$attendanceId')
          .get();

      if (!snapshot.exists) {
        throw Exception('Attendance record not found');
      }

      final attendance = AttendanceModel.fromRealtimeDB(
        attendanceId,
        Map<String, dynamic>.from(snapshot.value as Map),
      );

      if (attendance.hasCheckedOut) {
        throw Exception('Already checked out for today');
      }

      final now = DateTime.now();
      await _database.ref('attendance/$userId/$attendanceId').update({
        'checkOutTime': now.millisecondsSinceEpoch,
        'checkOutLatitude': latitude,
        'checkOutLongitude': longitude,
        'checkOutAddress': address,
        'status': AttendanceStatus.checkedOut.name,
      });

      return attendance.copyWith(
        checkOutTime: now,
        checkOutLatitude: latitude,
        checkOutLongitude: longitude,
        checkOutAddress: address,
        status: AttendanceStatus.checkedOut,
      );
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  Future<List<AttendanceModel>> getUserAttendanceHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      // Get all attendance without orderByChild to avoid Firebase index requirement
      final snapshot = await _database
          .ref('attendance/$userId')
          .get();

      if (snapshot.exists) {
        final List<AttendanceModel> history = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          history.add(AttendanceModel.fromRealtimeDB(
            key,
            Map<String, dynamic>.from(value),
          ));
        });
        // Sort by date descending (client-side)
        history.sort((a, b) => b.date.compareTo(a.date));
        // Apply limit client-side
        if (history.length > limit) {
          return history.sublist(0, limit);
        }
        return history;
      }
      return [];
    } catch (e) {
      print('Failed to get attendance history: $e');
      throw Exception('Failed to get attendance history: $e');
    }
  }

  /// Get subordinates attendance including absent users
  Future<List<AttendanceModel>> getSubordinatesAttendanceWithAbsent(
    List<Map<String, dynamic>> subordinatesInfo, {
    DateTime? date,
  }) async {
    try {
      if (subordinatesInfo.isEmpty) return [];

      final targetDate = date ?? DateTime.now();
      final dateKey = _getDateKey(targetDate);
      
      final List<AttendanceModel> attendanceList = [];

      for (final subordinate in subordinatesInfo) {
        final userId = subordinate['id'] as String;
        final userName = subordinate['name'] as String;
        final companyId = subordinate['companyId'] as String? ?? '';
        final corpId = subordinate['corpId'] as String? ?? '';
        
        final snapshot = await _database
            .ref('attendance/$userId/$dateKey')
            .get();

        if (snapshot.exists) {
          attendanceList.add(AttendanceModel.fromRealtimeDB(
            dateKey,
            Map<String, dynamic>.from(snapshot.value as Map),
          ));
        } else {
          // Add absent record for subordinate who hasn't checked in
          attendanceList.add(AttendanceModel(
            id: dateKey,
            oderId: userId,
            userName: userName,
            companyId: companyId,
            corpId: corpId,
            date: targetDate,
            status: AttendanceStatus.absent,
          ));
        }
      }

      // Sort by name for consistent display
      attendanceList.sort((a, b) => a.userName.compareTo(b.userName));

      return attendanceList;
    } catch (e) {
      throw Exception('Failed to get subordinates attendance: $e');
    }
  }

  Future<List<AttendanceModel>> getSubordinatesAttendance(
    List<String> subordinateIds, {
    DateTime? date,
  }) async {
    try {
      if (subordinateIds.isEmpty) return [];

      final targetDate = date ?? DateTime.now();
      final dateKey = _getDateKey(targetDate);
      
      final List<AttendanceModel> attendanceList = [];

      for (final userId in subordinateIds) {
        final snapshot = await _database
            .ref('attendance/$userId/$dateKey')
            .get();

        if (snapshot.exists) {
          attendanceList.add(AttendanceModel.fromRealtimeDB(
            dateKey,
            Map<String, dynamic>.from(snapshot.value as Map),
          ));
        }
      }

      return attendanceList;
    } catch (e) {
      throw Exception('Failed to get subordinates attendance: $e');
    }
  }

  Stream<AttendanceModel?> streamTodayAttendance(String userId) {
    final now = DateTime.now();
    final dateKey = _getDateKey(now);

    return _database
        .ref('attendance/$userId/$dateKey')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        return AttendanceModel.fromRealtimeDB(
          dateKey,
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }
}
