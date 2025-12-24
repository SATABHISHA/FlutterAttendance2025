import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskLoadAssignedTo extends TaskEvent {
  final String oderId;

  const TaskLoadAssignedTo({required this.oderId});

  @override
  List<Object?> get props => [oderId];
}

class TaskLoadAssignedBy extends TaskEvent {
  final String oderId;

  const TaskLoadAssignedBy({required this.oderId});

  @override
  List<Object?> get props => [oderId];
}

class TaskCreate extends TaskEvent {
  final String title;
  final String description;
  final String assignedTo;
  final String assignedToName;
  final String assignedBy;
  final String assignedByName;
  final String companyId;
  final String corpId;
  final TaskPriority priority;
  final DateTime? dueDate;

  const TaskCreate({
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.assignedToName,
    required this.assignedBy,
    required this.assignedByName,
    required this.companyId,
    required this.corpId,
    required this.priority,
    this.dueDate,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        assignedTo,
        assignedToName,
        assignedBy,
        assignedByName,
        companyId,
        corpId,
        priority,
        dueDate,
      ];
}

class TaskUpdateStatus extends TaskEvent {
  final String taskId;
  final TaskStatus status;

  const TaskUpdateStatus({
    required this.taskId,
    required this.status,
  });

  @override
  List<Object?> get props => [taskId, status];
}

class TaskSubmitReport extends TaskEvent {
  final String taskId;
  final String report;

  const TaskSubmitReport({
    required this.taskId,
    required this.report,
  });

  @override
  List<Object?> get props => [taskId, report];
}

// Event for subordinate to complete task with remarks
class TaskCompleteWithRemarks extends TaskEvent {
  final String taskId;
  final String remarks;

  const TaskCompleteWithRemarks({
    required this.taskId,
    required this.remarks,
  });

  @override
  List<Object?> get props => [taskId, remarks];
}

// Event for supervisor to review task
class TaskReview extends TaskEvent {
  final String taskId;
  final TaskReviewStatus reviewStatus;
  final String? feedback;

  const TaskReview({
    required this.taskId,
    required this.reviewStatus,
    this.feedback,
  });

  @override
  List<Object?> get props => [taskId, reviewStatus, feedback];
}

// Event for subordinate to report daily task (self-created)
class TaskReportDaily extends TaskEvent {
  final String title;
  final String description;
  final String userId;
  final String userName;
  final String supervisorId;
  final String supervisorName;
  final String companyId;
  final String corpId;

  const TaskReportDaily({
    required this.title,
    required this.description,
    required this.userId,
    required this.userName,
    required this.supervisorId,
    required this.supervisorName,
    required this.companyId,
    required this.corpId,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        userId,
        userName,
        supervisorId,
        supervisorName,
        companyId,
        corpId,
      ];
}

// Event to load tasks by date
class TaskLoadByDate extends TaskEvent {
  final String userId;
  final DateTime date;
  final bool isSupervisor;

  const TaskLoadByDate({
    required this.userId,
    required this.date,
    this.isSupervisor = false,
  });

  @override
  List<Object?> get props => [userId, date, isSupervisor];
}

// Event to load subordinate tasks for supervisor
class TaskLoadSubordinateTasks extends TaskEvent {
  final String supervisorId;
  final String subordinateId;
  final DateTime? date;

  const TaskLoadSubordinateTasks({
    required this.supervisorId,
    required this.subordinateId,
    this.date,
  });

  @override
  List<Object?> get props => [supervisorId, subordinateId, date];
}

class TaskDelete extends TaskEvent {
  final String taskId;

  const TaskDelete({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}
