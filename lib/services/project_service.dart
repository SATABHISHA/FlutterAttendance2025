import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import '../models/project_model.dart';

class ProjectService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Create a new project
  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required String companyId,
    required String corpId,
    required LocationBoundary locationBoundary,
    required String address,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      final newProjectRef = _database.ref('projects').push();
      final projectId = newProjectRef.key!;

      final project = ProjectModel(
        id: projectId,
        name: name,
        description: description,
        companyId: companyId,
        corpId: corpId,
        locationBoundary: locationBoundary,
        address: address,
        startDate: startDate,
        endDate: endDate,
        status: ProjectStatus.active,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: DateTime.now(),
      );

      await newProjectRef.set(project.toRealtimeDB());

      // Index by company
      await _database.ref('company_projects/$companyId/$projectId').set(true);

      return project;
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all projects for a company
  Future<List<ProjectModel>> getCompanyProjects(String companyId) async {
    try {
      final projectIdsSnapshot = await _database.ref('company_projects/$companyId').get();
      
      if (!projectIdsSnapshot.exists) {
        return [];
      }

      final projectIds = (projectIdsSnapshot.value as Map).keys.toList();
      final projects = <ProjectModel>[];

      for (final projectId in projectIds) {
        final projectSnapshot = await _database.ref('projects/$projectId').get();
        if (projectSnapshot.exists) {
          projects.add(ProjectModel.fromRealtimeDB(
            projectId.toString(),
            Map<String, dynamic>.from(projectSnapshot.value as Map),
          ));
        }
      }

      projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return projects;
    } catch (e) {
      throw Exception('Failed to get projects: $e');
    }
  }

  // Get active projects for a company
  Future<List<ProjectModel>> getActiveProjects(String companyId) async {
    try {
      final projects = await getCompanyProjects(companyId);
      return projects.where((p) => p.isActive).toList();
    } catch (e) {
      throw Exception('Failed to get active projects: $e');
    }
  }

  // Update project
  Future<void> updateProject(ProjectModel project) async {
    try {
      await _database.ref('projects/${project.id}').update({
        ...project.toRealtimeDB(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  // Delete project
  Future<void> deleteProject(String projectId, String companyId) async {
    try {
      await _database.ref('projects/$projectId').remove();
      await _database.ref('company_projects/$companyId/$projectId').remove();
      
      // Remove all assignments for this project
      final assignmentsSnapshot = await _database.ref('project_assignments')
          .orderByChild('projectId')
          .equalTo(projectId)
          .get();
      
      if (assignmentsSnapshot.exists) {
        final assignments = assignmentsSnapshot.value as Map;
        for (final assignmentId in assignments.keys) {
          await _database.ref('project_assignments/$assignmentId').remove();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // Assign project to user
  Future<ProjectAssignment> assignProjectToUser({
    required String projectId,
    required String projectName,
    required String userId,
    required String userName,
    required String assignedBy,
    required String assignedByName,
    required LocationBoundary locationBoundary,
    required String address,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final newAssignmentRef = _database.ref('project_assignments').push();
      final assignmentId = newAssignmentRef.key!;

      final assignment = ProjectAssignment(
        id: assignmentId,
        projectId: projectId,
        projectName: projectName,
        userId: userId,
        userName: userName,
        assignedBy: assignedBy,
        assignedByName: assignedByName,
        locationBoundary: locationBoundary,
        address: address,
        startDate: startDate,
        endDate: endDate,
        isActive: true,
        assignedAt: DateTime.now(),
      );

      await newAssignmentRef.set(assignment.toRealtimeDB());

      // Index by user
      await _database.ref('user_assignments/$userId/$assignmentId').set(true);
      // Index by project
      await _database.ref('project_user_assignments/$projectId/$assignmentId').set(true);

      return assignment;
    } catch (e) {
      throw Exception('Failed to assign project: $e');
    }
  }

  // Get user's project assignments
  Future<List<ProjectAssignment>> getUserAssignments(String userId) async {
    try {
      final assignmentIdsSnapshot = await _database.ref('user_assignments/$userId').get();
      
      if (!assignmentIdsSnapshot.exists) {
        return [];
      }

      final assignmentIds = (assignmentIdsSnapshot.value as Map).keys.toList();
      final assignments = <ProjectAssignment>[];

      for (final assignmentId in assignmentIds) {
        final assignmentSnapshot = await _database.ref('project_assignments/$assignmentId').get();
        if (assignmentSnapshot.exists) {
          assignments.add(ProjectAssignment.fromRealtimeDB(
            assignmentId.toString(),
            Map<String, dynamic>.from(assignmentSnapshot.value as Map),
          ));
        }
      }

      assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return assignments;
    } catch (e) {
      throw Exception('Failed to get user assignments: $e');
    }
  }

  // Get active assignments for a user
  Future<List<ProjectAssignment>> getActiveUserAssignments(String userId) async {
    try {
      final assignments = await getUserAssignments(userId);
      return assignments.where((a) => a.isCurrentlyActive).toList();
    } catch (e) {
      throw Exception('Failed to get active assignments: $e');
    }
  }

  // Update assignment
  Future<void> updateAssignment(ProjectAssignment assignment) async {
    try {
      await _database.ref('project_assignments/${assignment.id}').update(
        assignment.toRealtimeDB(),
      );
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  // Deactivate assignment
  Future<void> deactivateAssignment(String assignmentId) async {
    try {
      await _database.ref('project_assignments/$assignmentId').update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate assignment: $e');
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId, String userId, String projectId) async {
    try {
      await _database.ref('project_assignments/$assignmentId').remove();
      await _database.ref('user_assignments/$userId/$assignmentId').remove();
      await _database.ref('project_user_assignments/$projectId/$assignmentId').remove();
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // Check if user is within allowed location boundary
  bool isWithinBoundary(
    double userLat,
    double userLng,
    LocationBoundary boundary,
  ) {
    if (boundary.isCircular) {
      // Check circular boundary
      final distance = _calculateDistance(
        userLat,
        userLng,
        boundary.center.latitude,
        boundary.center.longitude,
      );
      return distance <= boundary.radiusInMeters;
    } else if (boundary.polygonPoints != null && boundary.polygonPoints!.length >= 3) {
      // Check polygon boundary using ray casting algorithm
      return _isPointInPolygon(userLat, userLng, boundary.polygonPoints!);
    }
    return false;
  }

  // Calculate distance between two points in meters using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Ray casting algorithm for point in polygon
  bool _isPointInPolygon(double lat, double lng, List<GeoPoint> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      if (((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // Check if user can check in based on active assignments
  Future<Map<String, dynamic>> canUserCheckIn(String userId, double lat, double lng) async {
    try {
      final activeAssignments = await getActiveUserAssignments(userId);
      
      if (activeAssignments.isEmpty) {
        return {
          'canCheckIn': false,
          'reason': 'No active project assigned. Please contact your supervisor.',
          'assignment': null,
        };
      }

      // Check each active assignment for valid location
      for (final assignment in activeAssignments) {
        if (isWithinBoundary(lat, lng, assignment.locationBoundary)) {
          return {
            'canCheckIn': true,
            'reason': null,
            'assignment': assignment,
          };
        }
      }

      return {
        'canCheckIn': false,
        'reason': 'You are not at the assigned project location. Please check-in from the designated area.',
        'assignment': activeAssignments.first,
      };
    } catch (e) {
      throw Exception('Failed to check check-in eligibility: $e');
    }
  }

  // Stream user's active assignments
  Stream<List<ProjectAssignment>> streamUserAssignments(String userId) {
    return _database.ref('user_assignments/$userId').onValue.asyncMap((event) async {
      if (!event.snapshot.exists) {
        return <ProjectAssignment>[];
      }

      final assignmentIds = (event.snapshot.value as Map).keys.toList();
      final assignments = <ProjectAssignment>[];

      for (final assignmentId in assignmentIds) {
        final assignmentSnapshot = await _database.ref('project_assignments/$assignmentId').get();
        if (assignmentSnapshot.exists) {
          assignments.add(ProjectAssignment.fromRealtimeDB(
            assignmentId.toString(),
            Map<String, dynamic>.from(assignmentSnapshot.value as Map),
          ));
        }
      }

      assignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return assignments;
    });
  }

  // Get project by ID
  Future<ProjectModel?> getProject(String projectId) async {
    try {
      final snapshot = await _database.ref('projects/$projectId').get();
      if (snapshot.exists) {
        return ProjectModel.fromRealtimeDB(
          projectId,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  // Get assignments for a project
  Future<List<ProjectAssignment>> getProjectAssignments(String projectId) async {
    try {
      final assignmentIdsSnapshot = await _database.ref('project_user_assignments/$projectId').get();
      
      if (!assignmentIdsSnapshot.exists) {
        return [];
      }

      final assignmentIds = (assignmentIdsSnapshot.value as Map).keys.toList();
      final assignments = <ProjectAssignment>[];

      for (final assignmentId in assignmentIds) {
        final assignmentSnapshot = await _database.ref('project_assignments/$assignmentId').get();
        if (assignmentSnapshot.exists) {
          assignments.add(ProjectAssignment.fromRealtimeDB(
            assignmentId.toString(),
            Map<String, dynamic>.from(assignmentSnapshot.value as Map),
          ));
        }
      }

      return assignments;
    } catch (e) {
      throw Exception('Failed to get project assignments: $e');
    }
  }

  // Create an attendance request for users without project
  Future<void> createAttendanceRequest({
    required String userId,
    required String userName,
    required String supervisorId,
    required String reason,
    required DateTime requestDate,
  }) async {
    try {
      final requestRef = _database.ref('attendance_requests').push();
      await requestRef.set({
        'userId': userId,
        'userName': userName,
        'supervisorId': supervisorId,
        'reason': reason,
        'requestDate': requestDate.millisecondsSinceEpoch,
        'status': 'pending', // pending, approved, rejected
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Index by supervisor for easy lookup
      await _database.ref('supervisor_attendance_requests/$supervisorId/${requestRef.key}').set(true);
      // Index by user
      await _database.ref('user_attendance_requests/$userId/${requestRef.key}').set(true);
    } catch (e) {
      throw Exception('Failed to create attendance request: $e');
    }
  }

  // Get pending attendance requests for a supervisor
  Future<List<Map<String, dynamic>>> getPendingAttendanceRequests(String supervisorId) async {
    try {
      final requestIdsSnapshot = await _database.ref('supervisor_attendance_requests/$supervisorId').get();
      
      if (!requestIdsSnapshot.exists) {
        return [];
      }

      final requestIds = (requestIdsSnapshot.value as Map).keys.toList();
      final requests = <Map<String, dynamic>>[];

      for (final requestId in requestIds) {
        final requestSnapshot = await _database.ref('attendance_requests/$requestId').get();
        if (requestSnapshot.exists) {
          final data = Map<String, dynamic>.from(requestSnapshot.value as Map);
          if (data['status'] == 'pending') {
            data['id'] = requestId;
            requests.add(data);
          }
        }
      }

      return requests;
    } catch (e) {
      throw Exception('Failed to get attendance requests: $e');
    }
  }

  // Approve or reject attendance request
  Future<void> updateAttendanceRequestStatus(String requestId, String status) async {
    try {
      await _database.ref('attendance_requests/$requestId').update({
        'status': status,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update attendance request: $e');
    }
  }

  // Check if user has approved attendance request for today
  Future<bool> hasApprovedAttendanceRequest(String userId) async {
    try {
      final requestIdsSnapshot = await _database.ref('user_attendance_requests/$userId').get();
      
      if (!requestIdsSnapshot.exists) {
        return false;
      }

      final requestIds = (requestIdsSnapshot.value as Map).keys.toList();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      for (final requestId in requestIds) {
        final requestSnapshot = await _database.ref('attendance_requests/$requestId').get();
        if (requestSnapshot.exists) {
          final data = Map<String, dynamic>.from(requestSnapshot.value as Map);
          if (data['status'] == 'approved') {
            final requestDate = DateTime.fromMillisecondsSinceEpoch(data['requestDate']);
            if (requestDate.isAfter(todayStart) && requestDate.isBefore(todayEnd)) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}
