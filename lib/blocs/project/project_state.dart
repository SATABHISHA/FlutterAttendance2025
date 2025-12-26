import 'package:equatable/equatable.dart';
import '../../models/project_model.dart';

enum ProjectStateStatus { initial, loading, loaded, error }

class ProjectState extends Equatable {
  final ProjectStateStatus status;
  final List<ProjectModel> projects;
  final List<ProjectAssignment> userAssignments;
  final List<ProjectAssignment> projectAssignments;
  final String? errorMessage;
  final bool canCheckIn;
  final String? checkInRestrictionReason;
  final ProjectAssignment? activeAssignment;

  const ProjectState({
    this.status = ProjectStateStatus.initial,
    this.projects = const [],
    this.userAssignments = const [],
    this.projectAssignments = const [],
    this.errorMessage,
    this.canCheckIn = false,
    this.checkInRestrictionReason,
    this.activeAssignment,
  });

  ProjectState copyWith({
    ProjectStateStatus? status,
    List<ProjectModel>? projects,
    List<ProjectAssignment>? userAssignments,
    List<ProjectAssignment>? projectAssignments,
    String? errorMessage,
    bool? canCheckIn,
    String? checkInRestrictionReason,
    ProjectAssignment? activeAssignment,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      userAssignments: userAssignments ?? this.userAssignments,
      projectAssignments: projectAssignments ?? this.projectAssignments,
      errorMessage: errorMessage,
      canCheckIn: canCheckIn ?? this.canCheckIn,
      checkInRestrictionReason: checkInRestrictionReason,
      activeAssignment: activeAssignment ?? this.activeAssignment,
    );
  }

  // Helper getters
  List<ProjectModel> get activeProjects => 
      projects.where((p) => p.isActive).toList();
  
  List<ProjectAssignment> get activeUserAssignments =>
      userAssignments.where((a) => a.isCurrentlyActive).toList();

  @override
  List<Object?> get props => [
        status,
        projects,
        userAssignments,
        projectAssignments,
        errorMessage,
        canCheckIn,
        checkInRestrictionReason,
        activeAssignment,
      ];
}
