import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

enum TaskStateStatus { initial, loading, loaded, error }

class TaskState extends Equatable {
  final TaskStateStatus status;
  final List<TaskModel> assignedToMe;
  final List<TaskModel> assignedByMe;
  final List<TaskModel> tasksByDate;
  final List<TaskModel> subordinateTasks;
  final String? errorMessage;
  final bool isCreating;
  final bool isUpdating;

  const TaskState({
    this.status = TaskStateStatus.initial,
    this.assignedToMe = const [],
    this.assignedByMe = const [],
    this.tasksByDate = const [],
    this.subordinateTasks = const [],
    this.errorMessage,
    this.isCreating = false,
    this.isUpdating = false,
  });

  int get pendingTasksCount =>
      assignedToMe.where((t) => t.status == TaskStatus.pending).length;

  int get inProgressTasksCount =>
      assignedToMe.where((t) => t.status == TaskStatus.inProgress).length;

  int get completedTasksCount =>
      assignedToMe.where((t) => t.status == TaskStatus.completed).length;

  int get overdueTasksCount =>
      assignedToMe.where((t) => t.isOverdue).length;
      
  int get approvedTasksCount =>
      assignedToMe.where((t) => t.reviewStatus == TaskReviewStatus.approved).length;
      
  int get rejectedTasksCount =>
      assignedToMe.where((t) => t.reviewStatus == TaskReviewStatus.rejected).length;
      
  int get dailyReportedTasksCount =>
      assignedToMe.where((t) => t.isDaily).length;

  TaskState copyWith({
    TaskStateStatus? status,
    List<TaskModel>? assignedToMe,
    List<TaskModel>? assignedByMe,
    List<TaskModel>? tasksByDate,
    List<TaskModel>? subordinateTasks,
    String? errorMessage,
    bool? isCreating,
    bool? isUpdating,
  }) {
    return TaskState(
      status: status ?? this.status,
      assignedToMe: assignedToMe ?? this.assignedToMe,
      assignedByMe: assignedByMe ?? this.assignedByMe,
      tasksByDate: tasksByDate ?? this.tasksByDate,
      subordinateTasks: subordinateTasks ?? this.subordinateTasks,
      errorMessage: errorMessage ?? this.errorMessage,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        assignedToMe,
        assignedByMe,
        tasksByDate,
        subordinateTasks,
        errorMessage,
        isCreating,
        isUpdating,
      ];
}
