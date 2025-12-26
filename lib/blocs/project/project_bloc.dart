import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/project_service.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectService _projectService;

  ProjectBloc({required ProjectService projectService})
      : _projectService = projectService,
        super(const ProjectState()) {
    on<ProjectLoadAll>(_onLoadAll);
    on<ProjectLoadActive>(_onLoadActive);
    on<ProjectCreate>(_onCreate);
    on<ProjectUpdate>(_onUpdate);
    on<ProjectDelete>(_onDelete);
    on<ProjectAssign>(_onAssign);
    on<ProjectLoadUserAssignments>(_onLoadUserAssignments);
    on<ProjectLoadActiveUserAssignments>(_onLoadActiveUserAssignments);
    on<ProjectUpdateAssignment>(_onUpdateAssignment);
    on<ProjectDeactivateAssignment>(_onDeactivateAssignment);
    on<ProjectDeleteAssignment>(_onDeleteAssignment);
    on<ProjectCheckCanCheckIn>(_onCheckCanCheckIn);
    on<ProjectLoadAssignments>(_onLoadProjectAssignments);
  }

  Future<void> _onLoadAll(
    ProjectLoadAll event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final projects = await _projectService.getCompanyProjects(event.companyId);
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projects: projects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadActive(
    ProjectLoadActive event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final projects = await _projectService.getActiveProjects(event.companyId);
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projects: projects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreate(
    ProjectCreate event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final project = await _projectService.createProject(
        name: event.name,
        description: event.description,
        companyId: event.companyId,
        corpId: event.corpId,
        locationBoundary: event.locationBoundary,
        address: event.address,
        startDate: event.startDate,
        endDate: event.endDate,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
      );

      final updatedProjects = [project, ...state.projects];
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projects: updatedProjects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    ProjectUpdate event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      await _projectService.updateProject(event.project);

      final updatedProjects = state.projects.map((p) {
        return p.id == event.project.id ? event.project : p;
      }).toList();

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projects: updatedProjects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    ProjectDelete event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      await _projectService.deleteProject(event.projectId, event.companyId);

      final updatedProjects = state.projects
          .where((p) => p.id != event.projectId)
          .toList();

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projects: updatedProjects,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAssign(
    ProjectAssign event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final assignment = await _projectService.assignProjectToUser(
        projectId: event.projectId,
        projectName: event.projectName,
        userId: event.userId,
        userName: event.userName,
        assignedBy: event.assignedBy,
        assignedByName: event.assignedByName,
        locationBoundary: event.locationBoundary,
        address: event.address,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      final updatedAssignments = [assignment, ...state.userAssignments];
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: updatedAssignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadUserAssignments(
    ProjectLoadUserAssignments event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final assignments = await _projectService.getUserAssignments(event.userId);
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: assignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadActiveUserAssignments(
    ProjectLoadActiveUserAssignments event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final assignments = await _projectService.getActiveUserAssignments(event.userId);
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: assignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateAssignment(
    ProjectUpdateAssignment event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      await _projectService.updateAssignment(event.assignment);

      final updatedAssignments = state.userAssignments.map((a) {
        return a.id == event.assignment.id ? event.assignment : a;
      }).toList();

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: updatedAssignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeactivateAssignment(
    ProjectDeactivateAssignment event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      await _projectService.deactivateAssignment(event.assignmentId);

      final updatedAssignments = state.userAssignments.map((a) {
        return a.id == event.assignmentId
            ? a.copyWith(isActive: false)
            : a;
      }).toList();

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: updatedAssignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteAssignment(
    ProjectDeleteAssignment event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      await _projectService.deleteAssignment(
        event.assignmentId,
        event.userId,
        event.projectId,
      );

      final updatedAssignments = state.userAssignments
          .where((a) => a.id != event.assignmentId)
          .toList();

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        userAssignments: updatedAssignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCheckCanCheckIn(
    ProjectCheckCanCheckIn event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final result = await _projectService.canUserCheckIn(
        event.userId,
        event.latitude,
        event.longitude,
      );

      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        canCheckIn: result['canCheckIn'] as bool,
        checkInRestrictionReason: result['reason'] as String?,
        activeAssignment: result['assignment'] as dynamic,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
        canCheckIn: false,
      ));
    }
  }

  Future<void> _onLoadProjectAssignments(
    ProjectLoadAssignments event,
    Emitter<ProjectState> emit,
  ) async {
    emit(state.copyWith(status: ProjectStateStatus.loading));

    try {
      final assignments = await _projectService.getProjectAssignments(event.projectId);
      emit(state.copyWith(
        status: ProjectStateStatus.loaded,
        projectAssignments: assignments,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ProjectStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
