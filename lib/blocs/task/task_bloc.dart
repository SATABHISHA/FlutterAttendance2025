import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService;

  TaskBloc({required TaskService taskService})
      : _taskService = taskService,
        super(const TaskState()) {
    on<TaskLoadAssignedTo>(_onLoadAssignedTo);
    on<TaskLoadAssignedBy>(_onLoadAssignedBy);
    on<TaskCreate>(_onCreateTask);
    on<TaskUpdateStatus>(_onUpdateStatus);
    on<TaskSubmitReport>(_onSubmitReport);
    on<TaskCompleteWithRemarks>(_onCompleteWithRemarks);
    on<TaskReview>(_onReviewTask);
    on<TaskReportDaily>(_onReportDaily);
    on<TaskLoadByDate>(_onLoadByDate);
    on<TaskLoadSubordinateTasks>(_onLoadSubordinateTasks);
    on<TaskDelete>(_onDeleteTask);
  }

  Future<void> _onLoadAssignedTo(
    TaskLoadAssignedTo event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStateStatus.loading));

    try {
      final tasks = await _taskService.getTasksAssignedToUser(event.oderId);

      emit(state.copyWith(
        status: TaskStateStatus.loaded,
        assignedToMe: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadAssignedBy(
    TaskLoadAssignedBy event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStateStatus.loading));

    try {
      final tasks = await _taskService.getTasksAssignedByUser(event.oderId);

      emit(state.copyWith(
        status: TaskStateStatus.loaded,
        assignedByMe: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateTask(
    TaskCreate event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));

    try {
      final task = await _taskService.createTask(
        title: event.title,
        description: event.description,
        assignedTo: event.assignedTo,
        assignedToName: event.assignedToName,
        assignedBy: event.assignedBy,
        assignedByName: event.assignedByName,
        companyId: event.companyId,
        corpId: event.corpId,
        priority: event.priority,
        dueDate: event.dueDate,
      );

      emit(state.copyWith(
        isCreating: false,
        assignedByMe: [task, ...state.assignedByMe],
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateStatus(
    TaskUpdateStatus event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true));

    try {
      await _taskService.updateTaskStatus(event.taskId, event.status);

      final updatedAssignedToMe = state.assignedToMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            status: event.status,
            completedAt: event.status == TaskStatus.completed ? DateTime.now() : null,
          );
        }
        return task;
      }).toList();

      final updatedAssignedByMe = state.assignedByMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            status: event.status,
            completedAt: event.status == TaskStatus.completed ? DateTime.now() : null,
          );
        }
        return task;
      }).toList();

      emit(state.copyWith(
        isUpdating: false,
        assignedToMe: updatedAssignedToMe,
        assignedByMe: updatedAssignedByMe,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitReport(
    TaskSubmitReport event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true));

    try {
      await _taskService.submitReport(event.taskId, event.report);

      final updatedAssignedToMe = state.assignedToMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            report: event.report,
            reportedAt: DateTime.now(),
          );
        }
        return task;
      }).toList();

      emit(state.copyWith(
        isUpdating: false,
        assignedToMe: updatedAssignedToMe,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCompleteWithRemarks(
    TaskCompleteWithRemarks event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true));

    try {
      await _taskService.completeTaskWithRemarks(event.taskId, event.remarks);

      final updatedAssignedToMe = state.assignedToMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            completionRemarks: event.remarks,
            reviewStatus: TaskReviewStatus.pending,
          );
        }
        return task;
      }).toList();

      final updatedAssignedByMe = state.assignedByMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            completionRemarks: event.remarks,
            reviewStatus: TaskReviewStatus.pending,
          );
        }
        return task;
      }).toList();

      emit(state.copyWith(
        isUpdating: false,
        assignedToMe: updatedAssignedToMe,
        assignedByMe: updatedAssignedByMe,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReviewTask(
    TaskReview event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true));

    try {
      await _taskService.reviewTask(event.taskId, event.reviewStatus, event.feedback);

      final updatedAssignedByMe = state.assignedByMe.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            reviewStatus: event.reviewStatus,
            reviewFeedback: event.feedback,
            reviewedAt: DateTime.now(),
          );
        }
        return task;
      }).toList();

      final updatedSubordinateTasks = state.subordinateTasks.map((task) {
        if (task.id == event.taskId) {
          return task.copyWith(
            reviewStatus: event.reviewStatus,
            reviewFeedback: event.feedback,
            reviewedAt: DateTime.now(),
          );
        }
        return task;
      }).toList();

      emit(state.copyWith(
        isUpdating: false,
        assignedByMe: updatedAssignedByMe,
        subordinateTasks: updatedSubordinateTasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onReportDaily(
    TaskReportDaily event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));

    try {
      final task = await _taskService.createDailyTask(
        title: event.title,
        description: event.description,
        userId: event.userId,
        userName: event.userName,
        supervisorId: event.supervisorId,
        supervisorName: event.supervisorName,
        companyId: event.companyId,
        corpId: event.corpId,
      );

      emit(state.copyWith(
        isCreating: false,
        assignedToMe: [task, ...state.assignedToMe],
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadByDate(
    TaskLoadByDate event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStateStatus.loading));

    try {
      final tasks = await _taskService.getTasksByDate(event.userId, event.date);

      emit(state.copyWith(
        status: TaskStateStatus.loaded,
        tasksByDate: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadSubordinateTasks(
    TaskLoadSubordinateTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStateStatus.loading));

    try {
      final tasks = await _taskService.getSubordinateTasks(
        event.supervisorId,
        event.subordinateId,
        date: event.date,
      );

      emit(state.copyWith(
        status: TaskStateStatus.loaded,
        subordinateTasks: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteTask(
    TaskDelete event,
    Emitter<TaskState> emit,
  ) async {
    try {
      await _taskService.deleteTask(event.taskId);

      emit(state.copyWith(
        assignedByMe: state.assignedByMe.where((t) => t.id != event.taskId).toList(),
        assignedToMe: state.assignedToMe.where((t) => t.id != event.taskId).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
