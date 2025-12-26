import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class ExportService {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Export attendance records to CSV
  Future<String> exportAttendanceToCSV({
    required List<AttendanceModel> attendanceList,
    required String fileName,
    String? title,
  }) async {
    try {
      final List<List<dynamic>> rows = [];

      // Add title row if provided
      if (title != null) {
        rows.add([title]);
        rows.add([]); // Empty row
      }

      // Header row
      rows.add([
        'Date',
        'Employee Name',
        'Check-In Time',
        'Check-In Location',
        'Check-Out Time',
        'Check-Out Location',
        'Status',
        'Work Duration',
        'Country',
        'Timezone',
      ]);

      // Data rows
      for (final attendance in attendanceList) {
        rows.add([
          _dateFormat.format(attendance.date),
          attendance.userName,
          attendance.checkInTime != null 
              ? _timeFormat.format(attendance.checkInTime!) 
              : '-',
          attendance.checkInAddress ?? '-',
          attendance.checkOutTime != null 
              ? _timeFormat.format(attendance.checkOutTime!) 
              : '-',
          attendance.checkOutAddress ?? '-',
          _formatStatus(attendance.status),
          _formatDuration(attendance.workDuration),
          attendance.country ?? '-',
          attendance.timezone ?? '-',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export attendance to CSV: $e');
    }
  }

  /// Export team attendance report
  Future<String> exportTeamAttendanceReport({
    required List<AttendanceModel> attendanceList,
    required DateTime startDate,
    required DateTime endDate,
    String? teamName,
  }) async {
    try {
      final dateRange = '${_dateFormat.format(startDate)}_to_${_dateFormat.format(endDate)}';
      final fileName = 'team_attendance_${teamName ?? 'report'}_$dateRange';
      
      final List<List<dynamic>> rows = [];

      // Title
      rows.add(['Team Attendance Report']);
      rows.add(['Period: ${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}']);
      if (teamName != null) {
        rows.add(['Team: $teamName']);
      }
      rows.add(['Generated: ${_dateTimeFormat.format(DateTime.now())}']);
      rows.add([]); // Empty row

      // Summary statistics
      final totalRecords = attendanceList.length;
      final checkedInCount = attendanceList.where((a) => a.status == AttendanceStatus.checkedIn).length;
      final checkedOutCount = attendanceList.where((a) => a.status == AttendanceStatus.checkedOut).length;
      final absentCount = attendanceList.where((a) => a.status == AttendanceStatus.absent).length;

      rows.add(['Summary']);
      rows.add(['Total Records', totalRecords.toString()]);
      rows.add(['Checked In (Not yet checked out)', checkedInCount.toString()]);
      rows.add(['Checked Out (Complete)', checkedOutCount.toString()]);
      rows.add(['Absent', absentCount.toString()]);
      rows.add([]); // Empty row

      // Header row
      rows.add([
        'S.No',
        'Date',
        'Employee Name',
        'Check-In Time',
        'Check-In Location',
        'Check-Out Time',
        'Check-Out Location',
        'Status',
        'Work Duration (hrs)',
      ]);

      // Data rows
      int serialNo = 1;
      for (final attendance in attendanceList) {
        rows.add([
          serialNo++,
          _dateFormat.format(attendance.date),
          attendance.userName,
          attendance.checkInTime != null 
              ? _timeFormat.format(attendance.checkInTime!) 
              : '-',
          attendance.checkInAddress ?? '-',
          attendance.checkOutTime != null 
              ? _timeFormat.format(attendance.checkOutTime!) 
              : '-',
          attendance.checkOutAddress ?? '-',
          _formatStatus(attendance.status),
          _formatDurationHours(attendance.workDuration),
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export team attendance report: $e');
    }
  }

  /// Export individual employee attendance report
  Future<String> exportEmployeeAttendanceReport({
    required List<AttendanceModel> attendanceList,
    required String employeeName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final safeName = employeeName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final dateRange = '${_dateFormat.format(startDate)}_to_${_dateFormat.format(endDate)}';
      final fileName = 'attendance_${safeName}_$dateRange';
      
      final List<List<dynamic>> rows = [];

      // Title
      rows.add(['Employee Attendance Report']);
      rows.add(['Employee: $employeeName']);
      rows.add(['Period: ${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}']);
      rows.add(['Generated: ${_dateTimeFormat.format(DateTime.now())}']);
      rows.add([]); // Empty row

      // Summary
      final totalDays = attendanceList.length;
      final presentDays = attendanceList.where((a) => a.status != AttendanceStatus.absent).length;
      final absentDays = attendanceList.where((a) => a.status == AttendanceStatus.absent).length;
      final totalWorkHours = attendanceList
          .where((a) => a.workDuration != null)
          .fold<Duration>(Duration.zero, (prev, a) => prev + a.workDuration!);

      rows.add(['Summary']);
      rows.add(['Total Days', totalDays.toString()]);
      rows.add(['Present Days', presentDays.toString()]);
      rows.add(['Absent Days', absentDays.toString()]);
      rows.add(['Total Work Hours', _formatDuration(totalWorkHours)]);
      rows.add(['Average Work Hours/Day', presentDays > 0 
          ? (totalWorkHours.inMinutes / presentDays / 60).toStringAsFixed(2) 
          : '0']);
      rows.add([]); // Empty row

      // Header row
      rows.add([
        'S.No',
        'Date',
        'Day',
        'Check-In Time',
        'Check-In Location',
        'Check-Out Time',
        'Check-Out Location',
        'Status',
        'Work Duration',
      ]);

      // Data rows
      int serialNo = 1;
      final dayFormat = DateFormat('EEEE');
      for (final attendance in attendanceList) {
        rows.add([
          serialNo++,
          _dateFormat.format(attendance.date),
          dayFormat.format(attendance.date),
          attendance.checkInTime != null 
              ? _timeFormat.format(attendance.checkInTime!) 
              : '-',
          attendance.checkInAddress ?? '-',
          attendance.checkOutTime != null 
              ? _timeFormat.format(attendance.checkOutTime!) 
              : '-',
          attendance.checkOutAddress ?? '-',
          _formatStatus(attendance.status),
          _formatDuration(attendance.workDuration),
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export employee attendance report: $e');
    }
  }

  /// Export task report
  Future<String> exportTaskReport({
    required List<TaskModel> tasks,
    required String reportTitle,
    String? filterInfo,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'task_report_$timestamp';
      
      final List<List<dynamic>> rows = [];

      // Title
      rows.add([reportTitle]);
      if (filterInfo != null) {
        rows.add([filterInfo]);
      }
      rows.add(['Generated: ${_dateTimeFormat.format(DateTime.now())}']);
      rows.add([]); // Empty row

      // Summary
      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
      final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).length;
      final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).length;
      final approvedTasks = tasks.where((t) => t.reviewStatus == TaskReviewStatus.approved).length;
      final rejectedTasks = tasks.where((t) => t.reviewStatus == TaskReviewStatus.rejected).length;

      rows.add(['Summary']);
      rows.add(['Total Tasks', totalTasks.toString()]);
      rows.add(['Completed', completedTasks.toString()]);
      rows.add(['Pending', pendingTasks.toString()]);
      rows.add(['In Progress', inProgressTasks.toString()]);
      rows.add(['Approved', approvedTasks.toString()]);
      rows.add(['Rejected', rejectedTasks.toString()]);
      rows.add([]); // Empty row

      // Header row
      rows.add([
        'S.No',
        'Title',
        'Description',
        'Assigned To',
        'Assigned By',
        'Project',
        'Priority',
        'Status',
        'Review Status',
        'Created Date',
        'Due Date',
        'Completed Date',
      ]);

      // Data rows
      int serialNo = 1;
      for (final task in tasks) {
        rows.add([
          serialNo++,
          task.title,
          task.description,
          task.assignedToName,
          task.assignedByName,
          task.projectName ?? 'N/A',
          task.priority.name.toUpperCase(),
          task.status.name,
          task.reviewStatus?.name ?? 'N/A',
          _dateFormat.format(task.createdAt),
          task.dueDate != null ? _dateFormat.format(task.dueDate!) : '-',
          task.completedAt != null ? _dateFormat.format(task.completedAt!) : '-',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export task report: $e');
    }
  }

  /// Export performance report
  Future<String> exportPerformanceReport({
    required String userName,
    required Map<String, int> statistics,
    required List<TaskModel> recentTasks,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final safeName = userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final dateRange = '${_dateFormat.format(startDate)}_to_${_dateFormat.format(endDate)}';
      final fileName = 'performance_${safeName}_$dateRange';
      
      final List<List<dynamic>> rows = [];

      // Title
      rows.add(['Performance Report']);
      rows.add(['Employee: $userName']);
      rows.add(['Period: ${_dateFormat.format(startDate)} to ${_dateFormat.format(endDate)}']);
      rows.add(['Generated: ${_dateTimeFormat.format(DateTime.now())}']);
      rows.add([]); // Empty row

      // Statistics
      rows.add(['Performance Statistics']);
      statistics.forEach((key, value) {
        rows.add([key, value.toString()]);
      });
      
      // Calculate percentages
      final total = statistics['total'] ?? 0;
      if (total > 0) {
        rows.add([]); // Empty row
        rows.add(['Performance Metrics']);
        final approved = statistics['approved'] ?? 0;
        final rejected = statistics['rejected'] ?? 0;
        final completed = statistics['completed'] ?? 0;
        
        rows.add(['Completion Rate', '${(completed / total * 100).toStringAsFixed(1)}%']);
        rows.add(['Approval Rate', completed > 0 
            ? '${(approved / completed * 100).toStringAsFixed(1)}%' 
            : 'N/A']);
        rows.add(['Rejection Rate', completed > 0 
            ? '${(rejected / completed * 100).toStringAsFixed(1)}%' 
            : 'N/A']);
      }
      
      rows.add([]); // Empty row

      // Recent Tasks
      rows.add(['Recent Tasks']);
      rows.add([
        'Title',
        'Project',
        'Status',
        'Review Status',
        'Completed Date',
      ]);

      for (final task in recentTasks.take(20)) {
        rows.add([
          task.title,
          task.projectName ?? 'N/A',
          task.status.name,
          task.reviewStatus?.name ?? 'N/A',
          task.completedAt != null ? _dateFormat.format(task.completedAt!) : '-',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export performance report: $e');
    }
  }

  String _formatStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.checkedIn:
        return 'Checked In';
      case AttendanceStatus.checkedOut:
        return 'Checked Out';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '-';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatDurationHours(Duration? duration) {
    if (duration == null) return '-';
    return (duration.inMinutes / 60).toStringAsFixed(2);
  }

  /// Get the downloads directory path
  Future<String> getDownloadsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  /// Delete a file
  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
