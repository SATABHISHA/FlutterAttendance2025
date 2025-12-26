import 'package:equatable/equatable.dart';
import '../../models/project_model.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

// Load all projects for a company
class ProjectLoadAll extends ProjectEvent {
  final String companyId;

  const ProjectLoadAll({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

// Load active projects only
class ProjectLoadActive extends ProjectEvent {
  final String companyId;

  const ProjectLoadActive({required this.companyId});

  @override
  List<Object?> get props => [companyId];
}

// Create a new project
class ProjectCreate extends ProjectEvent {
  final String name;
  final String description;
  final String companyId;
  final String corpId;
  final LocationBoundary locationBoundary;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final String createdByName;

  const ProjectCreate({
    required this.name,
    required this.description,
    required this.companyId,
    required this.corpId,
    required this.locationBoundary,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdByName,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        companyId,
        corpId,
        locationBoundary,
        address,
        startDate,
        endDate,
        createdBy,
        createdByName,
      ];
}

// Update project
class ProjectUpdate extends ProjectEvent {
  final ProjectModel project;

  const ProjectUpdate({required this.project});

  @override
  List<Object?> get props => [project];
}

// Delete project
class ProjectDelete extends ProjectEvent {
  final String projectId;
  final String companyId;

  const ProjectDelete({
    required this.projectId,
    required this.companyId,
  });

  @override
  List<Object?> get props => [projectId, companyId];
}

// Assign project to user
class ProjectAssign extends ProjectEvent {
  final String projectId;
  final String projectName;
  final String userId;
  final String userName;
  final String assignedBy;
  final String assignedByName;
  final LocationBoundary locationBoundary;
  final String address;
  final DateTime startDate;
  final DateTime endDate;

  const ProjectAssign({
    required this.projectId,
    required this.projectName,
    required this.userId,
    required this.userName,
    required this.assignedBy,
    required this.assignedByName,
    required this.locationBoundary,
    required this.address,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [
        projectId,
        projectName,
        userId,
        userName,
        assignedBy,
        assignedByName,
        locationBoundary,
        address,
        startDate,
        endDate,
      ];
}

// Load user assignments
class ProjectLoadUserAssignments extends ProjectEvent {
  final String userId;

  const ProjectLoadUserAssignments({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Load active user assignments
class ProjectLoadActiveUserAssignments extends ProjectEvent {
  final String userId;

  const ProjectLoadActiveUserAssignments({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Update assignment
class ProjectUpdateAssignment extends ProjectEvent {
  final ProjectAssignment assignment;

  const ProjectUpdateAssignment({required this.assignment});

  @override
  List<Object?> get props => [assignment];
}

// Deactivate assignment
class ProjectDeactivateAssignment extends ProjectEvent {
  final String assignmentId;

  const ProjectDeactivateAssignment({required this.assignmentId});

  @override
  List<Object?> get props => [assignmentId];
}

// Delete assignment
class ProjectDeleteAssignment extends ProjectEvent {
  final String assignmentId;
  final String userId;
  final String projectId;

  const ProjectDeleteAssignment({
    required this.assignmentId,
    required this.userId,
    required this.projectId,
  });

  @override
  List<Object?> get props => [assignmentId, userId, projectId];
}

// Check if user can check in
class ProjectCheckCanCheckIn extends ProjectEvent {
  final String userId;
  final double latitude;
  final double longitude;

  const ProjectCheckCanCheckIn({
    required this.userId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [userId, latitude, longitude];
}

// Load project assignments (all users assigned to a project)
class ProjectLoadAssignments extends ProjectEvent {
  final String projectId;

  const ProjectLoadAssignments({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}
